package com.catchbangladesh.ams

import android.os.Handler
import android.os.Looper
import com.gg.reader.api.protocol.gx.EnumG
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
    @Volatile private var lastEmittedEpc = ""
    @Volatile private var lastEmittedAtMs = 0L

    fun isOpen(): Boolean = running.get()

    fun start(): Boolean {
        if (running.get()) {
            stop()
            Thread.sleep(200)
        }

        lastEmittedEpc = ""
        lastEmittedAtMs = 0L

        println("UhfSerialReader: start (epc parser v5)")

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
        // Same port/baud sequence as com.pda.uhfdemo.init.AppInit
        val baudRates = intArrayOf(115200, 460800)
        for (baud in baudRates) {
            try {
                SerialPortJNI.closePort()
                println("UhfSerialReader: Trying /dev/ttyS3 @ $baud")
                val result = SerialPortJNI.openPort("/dev/ttyS3", baud, 8, 1, 'N')
                if (result == 1) {
                    for (retry in 1..2) {
                        sendMessage(MsgAppGetBaseVersion())
                        if (waitForBaseVersion(timeoutMs = 1500)) {
                            println("UhfSerialReader: Connected on /dev/ttyS3 @ $baud")
                            return true
                        }
                        Thread.sleep(100)
                    }
                    SerialPortJNI.closePort()
                }
            } catch (t: Throwable) {
                println("UhfSerialReader: Open failed @ $baud: ${t.message}")
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
        val inventory = Message().apply {
            msgType = MsgType().apply {
                mt_8_11 = EnumG.MSG_TYPE_BIT_BASE
                msgId = EnumG.BaseMid_InventoryEpc.toByte()
            }
            cData = byteArrayOf(0, 0, 0, 1, 1)
            dataLen = cData.size
        }
        return sendMessage(inventory)
    }

    private fun sendMessage(message: Message): Boolean {
        return try {
            val bytes = message.toBytes(false)
            println("UhfSerialReader: sendMessage: ${bytes.joinToString(",") { byteHex(it) }}")
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
        val msgType = message.msgType ?: return

        // Sync ack for MsgAppGetBaseVersion uses mt_12 == "0" (see GClient.processMessage).
        if (msgType.mt_12 == "0" && (msgType.msgId.toInt() and 0xFF) == EnumG.AppMid_GetBaseVersion) {
            val version = MsgAppGetBaseVersion()
            version.cData = message.cData
            version.ackUnpack()
            if (version.rtCode.toInt() == 0) {
                versionAck = true
                println("UhfSerialReader: Base version: ${version.baseVersions}")
            }
            return
        }

        // Sync ack for inventory start (msgId 16).
        if (msgType.mt_12 == "0" && (msgType.msgId.toInt() and 0xFF) == EnumG.BaseMid_InventoryEpc) {
            println("UhfSerialReader: Inventory ack (rt=${message.cData?.firstOrNull()})")
            return
        }

        val msgId = msgType.msgId.toInt() and 0xFF

        val epc = parseEpc(message.cData) ?: parseEpcFromFrame(frame)
        if (epc != null) {
            println("UhfSerialReader: Parsed EPC: $epc")
            emitTag(epc)
        }

        if (msgId == EnumG.BaseLogMid_EpcOver) {
            val over = LogBaseEpcOver()
            over.cData = message.cData
            over.ackUnpack()
            onStatus(over.rtMsg ?: "Inventory complete")
            return
        }
    }

    private fun emitTag(epc: String) {
        if (!isValidEpcHex(epc)) {
            return
        }
        val now = System.currentTimeMillis()
        if (epc == lastEmittedEpc && now - lastEmittedAtMs < 400) {
            return
        }
        lastEmittedEpc = epc
        lastEmittedAtMs = now
        mainHandler.post { onTag(epc) }
    }

    private fun parseEpc(cData: ByteArray?): String? {
        if (cData == null || cData.isEmpty()) {
            return null
        }

        epcFromGxLengthByte(cData)?.let { return it }
        return epcFromEmbedded90(cData)
    }

    private fun parseEpcFromFrame(frame: ByteArray): String? {
        return epcFromEmbedded90(frame)
    }

    /**
     * GX PDA: cData[0] is EPC byte length N; EPC hex is cData[1..N].
     * e.g. 0C 90 00 ... 81 -> 900000000000088800000081
     */
    private fun epcFromGxLengthByte(cData: ByteArray): String? {
        if (cData.size < 13) {
            return null
        }
        val n = cData[0].toInt() and 0xFF
        if (n !in 8..62 || 1 + n > cData.size) {
            return null
        }
        val hex = bytesToHex(cData, 1, n)
        return if (isValidEpcHex(hex)) hex else null
    }

    /** Find 12-byte EPC (24 hex chars) starting with 0x90 inside a buffer. */
    private fun epcFromEmbedded90(data: ByteArray): String? {
        if (data.size < 12) {
            return null
        }
        for (start in 0..data.size - 12) {
            if (data[start] != 0x90.toByte()) {
                continue
            }
            val hex = bytesToHex(data, start, 12)
            if (isValidEpcHex(hex)) {
                return hex
            }
        }
        return null
    }

    private fun bytesToHex(data: ByteArray, offset: Int, length: Int): String {
        val sb = StringBuilder(length * 2)
        for (i in offset until offset + length) {
            val v = data[i].toInt() and 0xFF
            sb.append(HEX_DIGITS[v ushr 4])
            sb.append(HEX_DIGITS[v and 0x0F])
        }
        return sb.toString()
    }

    private fun byteHex(b: Byte): String {
        val v = b.toInt() and 0xFF
        return "${HEX_DIGITS[v ushr 4]}${HEX_DIGITS[v and 0x0F]}"
    }

    private fun isValidEpcHex(hex: String): Boolean {
        if (hex.length != 24 || !hex.startsWith("90")) {
            return false
        }
        if (hex.contains("FFFFF", ignoreCase = true)) {
            return false
        }
        return hex.all { it in '0'..'9' || it in 'A'..'F' || it in 'a'..'f' }
    }

    private companion object {
        private const val HEX_DIGITS = "0123456789ABCDEF"
    }
}


