package com.catchbangladesh.ams

import android.os.Handler
import android.os.Looper
import com.gg.reader.api.protocol.gx.EnumG
import com.gg.reader.api.protocol.gx.LogBaseEpcInfo
import com.gg.reader.api.protocol.gx.LogBaseEpcOver
import com.gg.reader.api.protocol.gx.Message
import com.gg.reader.api.protocol.gx.MsgAppGetBaseVersion
import com.gg.reader.api.protocol.gx.MsgBaseStop
import com.gg.reader.api.protocol.gx.MsgType
import com.gxwl.device.reader.dal.SerialPortJNI
import com.pda.uhfdemo.utils.PowerUtil
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class UhfSerialReader(
    private val onTag: (String) -> Unit,
    private val onStatus: (String) -> Unit = {},
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val running = AtomicBoolean(false)
    private val buffer = ByteArrayOutputStream()
    @Volatile private var versionAck = false

    fun isOpen(): Boolean = running.get()

    fun start(): Boolean {
        if (running.get()) return true
        
        // Power on the UHF module
        try {
            println("UhfSerialReader: Powering on RFID module (extended sequence)...")
            
            // 1. Standard PDA PowerUtil
            try { PowerUtil.power("1") } catch (_: Throwable) {}
            
            // 2. Try writing to common GPIO paths
            val powerPaths = arrayOf(
                "/proc/gpiocontrol/set_uhf" to "1",
                "/proc/gpiocontrol/set_bd" to "1",
                "/sys/cgp_ctrl/cgp_on" to "1",
                "/sys/cgp_ctrl/cgp_switch_vbat" to "1",
                "/sys/cgp_ctrl/cgp_uart_switch" to "0",
                "/sys/cgp_ctrl/cgp_vbus_5v" to "1"
            )
            
            for ((path, value) in powerPaths) {
                try {
                    java.io.FileWriter(path).use { it.write(value) }
                    println("UhfSerialReader: Wrote $value to $path")
                } catch (_: Throwable) {}
            }

            println("UhfSerialReader: Waiting for module to wake up...")
            Thread.sleep(1000) // Wait for module to stabilize
        } catch (t: Throwable) {
            println("UhfSerialReader: Power on error: ${t.message}")
        }

        if (!openReader()) {
            println("UhfSerialReader: All open attempts failed. Powering off.")
            stop() 
            return false
        }
        running.set(true)
        if (!sendInventoryStart()) {
            println("UhfSerialReader: sendInventoryStart failed. Powering off.")
            stop()
            return false
        }
        executor.execute { readLoop() }
        return true
    }

    fun stop(): Boolean {
        running.set(false)
        try {
            sendMessage(MsgBaseStop())
            Thread.sleep(100)
            SerialPortJNI.closePort()
            
            // Power off the UHF module
            println("UhfSerialReader: Powering off RFID module...")
            try { PowerUtil.power("0") } catch (_: Throwable) {}
            
            val offPaths = arrayOf(
                "/proc/gpiocontrol/set_uhf" to "0",
                "/proc/gpiocontrol/set_bd" to "0",
                "/sys/cgp_ctrl/cgp_on" to "0",
                "/sys/cgp_ctrl/cgp_switch_vbat" to "0",
                "/sys/cgp_ctrl/cgp_vbus_5v" to "0"
            )
            
            for ((path, value) in offPaths) {
                try {
                    java.io.FileWriter(path).use { it.write(value) }
                } catch (_: Throwable) {}
            }
            
            return true
        } catch (_: Throwable) {
            return false
        }
    }

    private fun openReader(): Boolean {
        val ports = arrayOf("/dev/ttyS3", "/dev/ttyS1", "/dev/ttyS0", "/dev/ttyS2", "/dev/ttyS4")
        val baudRates = intArrayOf(115200, 460800, 57600, 9600, 38400, 19200)
        
        for (port in ports) {
            for (baud in baudRates) {
                try {
                    println("UhfSerialReader: Trying $port @ $baud")
                    val result = SerialPortJNI.openPort(port, baud, 8, 1, 'N')
                    if (result == 1) {
                        // Sometimes the first message fails after power on, try twice
                        for (retry in 1..2) {
                            val versionReq = MsgAppGetBaseVersion()
                            sendMessage(versionReq)
                            if (waitForBaseVersion(timeoutMs = 1000)) {
                                println("UhfSerialReader: Success on $port @ $baud")
                                return true
                            }
                            Thread.sleep(100)
                        }
                        SerialPortJNI.closePort()
                    }
                } catch (t: Throwable) {
                    // ignore and try next
                }
            }
        }
        return false
    }

    private fun waitForBaseVersion(timeoutMs: Long = 1500L): Boolean {
        println("UhfSerialReader: Waiting for base version...")
        val deadline = System.currentTimeMillis() + timeoutMs
        versionAck = false
        while (System.currentTimeMillis() < deadline) {
            pollOnce()
            if (versionAck) {
                println("UhfSerialReader: Base version received!")
                return true
            }
            Thread.sleep(50)
        }
        println("UhfSerialReader: Timeout waiting for base version")
        return false
    }

    private fun sendInventoryStart(): Boolean {
        val msg = Message().apply {
            msgType = MsgType().apply {
                mt_8_11 = EnumG.MSG_TYPE_BIT_BASE
                msgId = 16
            }
            cData = byteArrayOf(0, 0, 0, 1, 1)
            dataLen = cData.size
        }
        return sendMessage(msg)
    }

    private fun sendMessage(message: Message): Boolean {
        return try {
            val bytes = message.toBytes(false)
            println("UhfSerialReader: sendMessage: ${bytes.joinToString(",") { "%02X".format(it) }}")
            SerialPortJNI.writePort(bytes)
            true
        } catch (t: Throwable) {
            mainHandler.post { onStatus(t.message ?: "UHF write failed") }
            false
        }
    }

    private fun readLoop() {
        while (running.get()) {
            pollOnce()
            Thread.sleep(20)
        }
    }

    private fun pollOnce() {
        try {
            val data = SerialPortJNI.readPort(256) ?: return
            if (data.isEmpty()) return
            println("UhfSerialReader: readPort data size: ${data.size}")
            buffer.write(data)
            parseBuffer()
        } catch (t: Throwable) {
            println("UhfSerialReader: readPort error: ${t.message}")
        }
    }

    private fun parseBuffer() {
        val bytes = buffer.toByteArray().toMutableList()
        if (bytes.isEmpty()) return

        while (bytes.isNotEmpty()) {
            val headIndex = bytes.indexOfFirst { it.toInt() and 0xFF == 0x5A }
            if (headIndex < 0) {
                bytes.clear()
                break
            }
            if (headIndex > 0) {
                repeat(headIndex) { bytes.removeAt(0) }
            }
            if (bytes.size < 7) break
            val dataLen = ((bytes[5].toInt() and 0xFF) shl 8) or (bytes[6].toInt() and 0xFF)
            val totalLen = 9 + dataLen
            if (bytes.size < totalLen) break
            val frame = ByteArray(totalLen)
            for (i in 0 until totalLen) frame[i] = bytes[i]
            repeat(totalLen) { bytes.removeAt(0) }
            handleFrame(frame)
        }

        buffer.reset()
        if (bytes.isNotEmpty()) {
            buffer.write(ByteArray(bytes.size) { bytes[it] })
        }
    }

    private fun handleFrame(frame: ByteArray) {
        val message = Message(frame)
        when {
            message.msgType?.mt_8_11 == EnumG.MSG_TYPE_BIT_APP && message.msgType?.msgId == EnumG.AppMid_GetBaseVersion.toByte() -> {
                val version = MsgAppGetBaseVersion()
                version.cData = message.cData
                version.ackUnpack()
                versionAck = true
            }
            message.msgType?.mt_8_11 == EnumG.MSG_TYPE_BIT_BASE && message.msgType?.msgId == EnumG.BaseLogMid_Epc.toByte() -> {
                val log = LogBaseEpcInfo()
                log.cData = message.cData
                log.ackUnpack()
                val epc = log.epc?.trim().orEmpty()
                println("UhfSerialReader: Parsed EPC: $epc")
                if (epc.isNotBlank()) {
                    mainHandler.post { onTag(epc) }
                }
            }
            message.msgType?.mt_8_11 == EnumG.MSG_TYPE_BIT_BASE && message.msgType?.msgId == EnumG.BaseLogMid_EpcOver.toByte() -> {
                val over = LogBaseEpcOver()
                over.cData = message.cData
                over.ackUnpack()
                onStatus(over.rtMsg ?: "Inventory complete")
            }
        }
    }
}


