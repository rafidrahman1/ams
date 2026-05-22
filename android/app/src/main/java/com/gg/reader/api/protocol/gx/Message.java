package com.gg.reader.api.protocol.gx;

import com.gg.reader.api.utils.BitBuffer;
import com.gg.reader.api.utils.Crc16Utils;
import com.gg.reader.api.utils.GLog;
import com.gg.reader.api.utils.HexUtils;

/* JADX INFO: loaded from: classes.dex */
public class Message {
    public static byte HEAD = 90;
    public static final int MSG_MAX_LEN = 1024;
    public byte[] cData;
    public byte[] crc;
    public byte[] crcData;
    public int dataLen;
    public byte[] msgData;
    public MsgType msgType;
    public int rs485Address;
    private byte rtCode;
    private String rtMsg;

    public void ackUnpack() {
    }

    public byte getRtCode() {
        return this.rtCode;
    }

    public String getRtMsg() {
        return this.rtMsg;
    }

    public void setRtCode(byte b) {
        this.rtCode = b;
    }

    public void setRtMsg(String str) {
        this.rtMsg = str;
    }

    public Message() {
        this.msgType = null;
        this.rs485Address = 0;
        this.dataLen = 0;
        this.cData = null;
        this.crc = null;
        this.crcData = null;
        this.msgData = null;
        this.rtCode = (byte) -1;
        this.rtMsg = "";
    }

    public Message(byte[] bArr) {
        this.msgType = null;
        this.rs485Address = 0;
        this.dataLen = 0;
        this.cData = null;
        this.crc = null;
        this.crcData = null;
        this.msgData = null;
        this.rtCode = (byte) -1;
        this.rtMsg = "";
        try {
            this.msgData = bArr;
            this.crcData = new byte[bArr.length - 3];
            BitBuffer bitBufferWrap = BitBuffer.wrap(bArr);
            bitBufferWrap.position(8);
            MsgType msgType = new MsgType(bitBufferWrap.get(new byte[4]));
            this.msgType = msgType;
            if (msgType.mt_13.equals("1")) {
                this.rs485Address = bitBufferWrap.getIntUnsigned(8);
            }
            int intUnsigned = bitBufferWrap.getIntUnsigned(16);
            this.dataLen = intUnsigned;
            if (intUnsigned > 0) {
                byte[] bArr2 = new byte[intUnsigned];
                this.cData = bArr2;
                this.cData = bitBufferWrap.get(bArr2);
            }
            int iPosition = bitBufferWrap.position();
            bitBufferWrap.position(8);
            this.crcData = bitBufferWrap.get(this.crcData);
            bitBufferWrap.position(iPosition);
            byte[] bArr3 = new byte[2];
            this.crc = bArr3;
            this.crc = bitBufferWrap.get(bArr3);
        } catch (Exception e) {
            GLog.e("Message unpacking error :" + e.getStackTrace());
        }
    }

    public byte[] toBytes() {
        return toBytes(false);
    }

    public byte[] toBytes(boolean z) {
        BitBuffer bitBufferAllocateDynamic = BitBuffer.allocateDynamic();
        bitBufferAllocateDynamic.put(HEAD);
        bitBufferAllocateDynamic.put(this.msgType.toBytes());
        if (z) {
            bitBufferAllocateDynamic.putInt(this.rs485Address, 8);
        }
        bitBufferAllocateDynamic.putInt(this.dataLen, 16);
        byte[] bArr = this.cData;
        if (bArr != null && bArr.length > 0 && bArr.length == this.dataLen) {
            bitBufferAllocateDynamic.put(bArr);
        }
        int iPosition = bitBufferAllocateDynamic.position();
        this.crcData = new byte[(bitBufferAllocateDynamic.position() / 8) - 1];
        bitBufferAllocateDynamic.position(8);
        this.crcData = bitBufferAllocateDynamic.get(this.crcData);
        bitBufferAllocateDynamic.position(iPosition);
        byte[] bArrShort2Bytes = HexUtils.short2Bytes(Crc16Utils.CRC_XModem(this.crcData));
        this.crc = bArrShort2Bytes;
        bitBufferAllocateDynamic.put(bArrShort2Bytes);
        byte[] bArrAsByteArray = bitBufferAllocateDynamic.asByteArray();
        this.msgData = bArrAsByteArray;
        return bArrAsByteArray;
    }

    public void pack() {
        this.dataLen = 0;
    }

    public void ackPack() {
        this.crcData = new byte[]{this.rtCode};
        this.dataLen = 1;
    }

    public void ackUnpack(byte[] bArr) {
        this.cData = bArr;
        ackUnpack();
    }

    public boolean checkCrc() {
        try {
            byte[] bArr = this.crcData;
            if (bArr == null || this.crc == null) {
                return false;
            }
            byte[] bArrShort2Bytes = HexUtils.short2Bytes(Crc16Utils.CRC_XModem(bArr));
            for (int i = 0; i < bArrShort2Bytes.length; i++) {
                if (this.crc[i] != bArrShort2Bytes[i]) {
                    return false;
                }
            }
            return true;
        } catch (Exception unused) {
            return false;
        }
    }
}
