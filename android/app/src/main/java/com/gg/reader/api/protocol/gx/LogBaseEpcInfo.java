package com.gg.reader.api.protocol.gx;

import android.bld.scan.configuration.ScanConfig;
import com.gg.reader.api.utils.BitBuffer;
import com.gg.reader.api.utils.DateTimeUtils;
import com.gg.reader.api.utils.HexUtils;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.TimeZone;

/* JADX INFO: loaded from: classes.dex */
public class LogBaseEpcInfo extends Message {
    private String EPC_2V2_challenge;
    private String EPC_2V2_tag_response;
    private int antId;
    private int ast010TM;
    private byte[] bEpc;
    private byte[] bEpcData;
    private byte[] bRes;
    private byte[] bTid;
    private byte[] bUser;
    private int childAntId;
    private int crc;
    private int ctesiusLtu27;
    private int ctesiusLtu31;
    private int cykeoRule;
    private DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    private String epc;
    private String epcData;
    private Long frequencyPoint;
    private int kunYue;
    private int pc;
    private int phase;
    private String quanray_rawData;
    private String quanray_temp;
    private String readerSerialNumber;
    private Long replySerialNumber;
    private String reserved;
    private int result;
    private int rssi;
    private int rssidBm;
    private int scr409TM;
    private String strUtc;
    private String tid;
    private String userdata;

    public String getEpc() {
        return this.epc;
    }

    public void setEpc(String str) {
        this.epc = str;
    }

    public byte[] getbEpc() {
        return this.bEpc;
    }

    public void setbEpc(byte[] bArr) {
        this.bEpc = bArr;
    }

    public int getPc() {
        return this.pc;
    }

    public void setPc(int i) {
        this.pc = i;
    }

    public int getAntId() {
        return this.antId;
    }

    public void setAntId(int i) {
        this.antId = i;
    }

    public int getRssi() {
        return this.rssi;
    }

    public void setRssi(int i) {
        this.rssi = i;
    }

    public int getResult() {
        return this.result;
    }

    public void setResult(int i) {
        this.result = i;
    }

    public String getTid() {
        return this.tid;
    }

    public void setTid(String str) {
        this.tid = str;
    }

    public byte[] getbTid() {
        return this.bTid;
    }

    public void setbTid(byte[] bArr) {
        this.bTid = bArr;
    }

    public String getUserdata() {
        return this.userdata;
    }

    public void setUserdata(String str) {
        this.userdata = str;
    }

    public byte[] getbUser() {
        return this.bUser;
    }

    public void setbUser(byte[] bArr) {
        this.bUser = bArr;
    }

    public String getReserved() {
        return this.reserved;
    }

    public void setReserved(String str) {
        this.reserved = str;
    }

    public byte[] getbRes() {
        return this.bRes;
    }

    public void setbRes(byte[] bArr) {
        this.bRes = bArr;
    }

    public int getChildAntId() {
        return this.childAntId;
    }

    public void setChildAntId(int i) {
        this.childAntId = i;
    }

    public String getStrUtc() {
        return this.strUtc;
    }

    public void setStrUtc(String str) {
        this.strUtc = str;
    }

    public Long getFrequencyPoint() {
        return this.frequencyPoint;
    }

    public void setFrequencyPoint(Long l) {
        this.frequencyPoint = l;
    }

    public int getPhase() {
        return this.phase;
    }

    public void setPhase(int i) {
        this.phase = i;
    }

    public String getEpcData() {
        return this.epcData;
    }

    public void setEpcData(String str) {
        this.epcData = str;
    }

    public byte[] getbEpcData() {
        return this.bEpcData;
    }

    public void setbEpcData(byte[] bArr) {
        this.bEpcData = bArr;
    }

    public int getCtesiusLtu27() {
        return this.ctesiusLtu27;
    }

    public void setCtesiusLtu27(int i) {
        this.ctesiusLtu27 = i;
    }

    public int getCtesiusLtu31() {
        return this.ctesiusLtu31;
    }

    public void setCtesiusLtu31(int i) {
        this.ctesiusLtu31 = i;
    }

    public String getReaderSerialNumber() {
        return this.readerSerialNumber;
    }

    public void setReaderSerialNumber(String str) {
        this.readerSerialNumber = str;
    }

    public Long getReplySerialNumber() {
        return this.replySerialNumber;
    }

    public void setReplySerialNumber(Long l) {
        this.replySerialNumber = l;
    }

    public int getRssidBm() {
        return this.rssidBm;
    }

    public void setRssidBm(int i) {
        this.rssidBm = i;
    }

    public int getKunYue() {
        return this.kunYue;
    }

    public void setKunYue(int i) {
        this.kunYue = i;
    }

    public int getCrc() {
        return this.crc;
    }

    public void setCrc(int i) {
        this.crc = i;
    }

    public String getEPC_2V2_challenge() {
        return this.EPC_2V2_challenge;
    }

    public void setEPC_2V2_challenge(String str) {
        this.EPC_2V2_challenge = str;
    }

    public String getEPC_2V2_tag_response() {
        return this.EPC_2V2_tag_response;
    }

    public void setEPC_2V2_tag_response(String str) {
        this.EPC_2V2_tag_response = str;
    }

    public int getCykeoRule() {
        return this.cykeoRule;
    }

    public void setCykeoRule(int i) {
        this.cykeoRule = i;
    }

    public String getQuanray_temp() {
        return this.quanray_temp;
    }

    public void setQuanray_temp(String str) {
        this.quanray_temp = str;
    }

    public String getQuanray_rawData() {
        return this.quanray_rawData;
    }

    public void setQuanray_rawData(String str) {
        this.quanray_rawData = str;
    }

    public int getScr409TM() {
        return this.scr409TM;
    }

    public void setScr409TM(int i) {
        this.scr409TM = i;
    }

    public int getAst010TM() {
        return this.ast010TM;
    }

    public void setAst010TM(int i) {
        this.ast010TM = i;
    }

    @Override // com.gg.reader.api.protocol.gx.Message
    public void pack() {
        super.pack();
    }

    @Override // com.gg.reader.api.protocol.gx.Message
    public void ackUnpack() {
        if (this.cData == null || this.cData.length <= 0) {
            return;
        }
        BitBuffer bitBufferWrap = BitBuffer.wrap(this.cData);
        bitBufferWrap.position(0);
        byte[] bArr = new byte[bitBufferWrap.getIntUnsigned(16)];
        this.bEpc = bArr;
        byte[] bArr2 = bitBufferWrap.get(bArr);
        this.bEpc = bArr2;
        if (bArr2.length > 0) {
            this.epc = HexUtils.bytes2HexString(bArr2);
        }
        this.pc = bitBufferWrap.getIntUnsigned(16);
        this.antId = bitBufferWrap.getIntUnsigned(8);
        while (bitBufferWrap.position() / 8 < this.cData.length) {
            int intUnsigned = bitBufferWrap.getIntUnsigned(8);
            if (intUnsigned == 32) {
                int intUnsigned2 = bitBufferWrap.getIntUnsigned(16);
                if (intUnsigned2 > 0) {
                    this.readerSerialNumber = new String(bitBufferWrap.get(new byte[intUnsigned2]), ScanConfig.SCAN_ENCODE_ASCII);
                }
            } else if (intUnsigned == 34) {
                this.replySerialNumber = Long.valueOf(bitBufferWrap.getLongUnsigned(32));
            } else if (intUnsigned == 44) {
                this.scr409TM = bitBufferWrap.getInt(16);
            } else if (intUnsigned == 48) {
                bitBufferWrap.getIntUnsigned(8);
            } else if (intUnsigned != 49) {
                switch (intUnsigned) {
                    case 1:
                        this.rssi = bitBufferWrap.getIntUnsigned(8);
                        break;
                    case 2:
                        this.result = bitBufferWrap.getIntUnsigned(8);
                        break;
                    case 3:
                        int intUnsigned3 = bitBufferWrap.getIntUnsigned(16);
                        if (intUnsigned3 > 0) {
                            byte[] bArr3 = new byte[intUnsigned3];
                            this.bTid = bArr3;
                            byte[] bArr4 = bitBufferWrap.get(bArr3);
                            this.bTid = bArr4;
                            this.tid = HexUtils.bytes2HexString(bArr4);
                        }
                        break;
                    case 4:
                        int intUnsigned4 = bitBufferWrap.getIntUnsigned(16);
                        if (intUnsigned4 > 0) {
                            byte[] bArr5 = new byte[intUnsigned4];
                            this.bUser = bArr5;
                            byte[] bArr6 = bitBufferWrap.get(bArr5);
                            this.bUser = bArr6;
                            this.userdata = HexUtils.bytes2HexString(bArr6);
                        }
                        break;
                    case 5:
                        int intUnsigned5 = bitBufferWrap.getIntUnsigned(16);
                        if (intUnsigned5 > 0) {
                            byte[] bArr7 = new byte[intUnsigned5];
                            this.bRes = bArr7;
                            byte[] bArr8 = bitBufferWrap.get(bArr7);
                            this.bRes = bArr8;
                            this.reserved = HexUtils.bytes2HexString(bArr8);
                        }
                        break;
                    case 6:
                        this.childAntId = bitBufferWrap.getIntUnsigned(8);
                        break;
                    case 7:
                        this.strUtc = this.dateFormat.format(DateTimeUtils.fromUtcToTimeZone((bitBufferWrap.getLong(32) * 1000) + (bitBufferWrap.getLong(32) / 1000), TimeZone.getDefault()));
                        break;
                    case 8:
                        this.frequencyPoint = Long.valueOf(bitBufferWrap.getLongUnsigned(32));
                        break;
                    case 9:
                        this.phase = bitBufferWrap.getIntUnsigned(8);
                        break;
                    case 10:
                        int intUnsigned6 = bitBufferWrap.getIntUnsigned(16);
                        if (intUnsigned6 > 0) {
                            byte[] bArr9 = new byte[intUnsigned6];
                            this.bEpcData = bArr9;
                            byte[] bArr10 = bitBufferWrap.get(bArr9);
                            this.bEpcData = bArr10;
                            this.epcData = HexUtils.bytes2HexString(bArr10);
                        }
                        break;
                    case 11:
                        int intUnsigned7 = bitBufferWrap.getIntUnsigned(16);
                        if (intUnsigned7 > 0) {
                            byte[] bArr11 = new byte[intUnsigned7];
                            bitBufferWrap.get(bArr11);
                            this.EPC_2V2_challenge = HexUtils.bytes2HexString(bArr11);
                        }
                        break;
                    case 12:
                        int intUnsigned8 = bitBufferWrap.getIntUnsigned(16);
                        if (intUnsigned8 > 0) {
                            byte[] bArr12 = new byte[intUnsigned8];
                            bitBufferWrap.get(bArr12);
                            this.EPC_2V2_tag_response = HexUtils.bytes2HexString(bArr12);
                        }
                        break;
                    default:
                        switch (intUnsigned) {
                            case 17:
                                this.ctesiusLtu27 = bitBufferWrap.getIntUnsigned(16);
                                break;
                            case 18:
                                this.ctesiusLtu31 = bitBufferWrap.getInt(16);
                                break;
                            case 19:
                                this.kunYue = bitBufferWrap.getIntUnsigned(16);
                                break;
                            case 20:
                                this.rssidBm = bitBufferWrap.getInt(16);
                                break;
                            case 21:
                                this.crc = bitBufferWrap.getIntUnsigned(16);
                                break;
                            case 22:
                                this.quanray_temp = String.valueOf(bitBufferWrap.getInt(16));
                                this.quanray_rawData = HexUtils.bytes2HexString(bitBufferWrap.get(new byte[6]));
                                break;
                            default:
                                switch (intUnsigned) {
                                    case 36:
                                        this.cykeoRule = bitBufferWrap.getIntUnsigned(8);
                                        break;
                                    case 37:
                                        int intUnsigned9 = bitBufferWrap.getIntUnsigned(16);
                                        if (intUnsigned9 > 0) {
                                            bitBufferWrap.get(new byte[intUnsigned9]);
                                        }
                                        break;
                                    case 38:
                                        try {
                                            int intUnsigned10 = bitBufferWrap.getIntUnsigned(16);
                                            if (intUnsigned10 > 0) {
                                                bitBufferWrap.get(new byte[intUnsigned10]);
                                            }
                                        } catch (Exception unused) {
                                        }
                                        break;
                                    case 39:
                                        bitBufferWrap.getIntUnsigned(8);
                                        break;
                                    case 40:
                                        this.ast010TM = bitBufferWrap.getInt(16);
                                        break;
                                }
                                break;
                        }
                        break;
                }
            } else {
                bitBufferWrap.getInt(16);
            }
        }
    }

    public String toString() {
        return "LogBaseEpcInfo{epc='" + this.epc + "', bEpc=" + Arrays.toString(this.bEpc) + ", pc=" + this.pc + ", antId=" + this.antId + ", rssi=" + this.rssi + ", result=" + this.result + ", tid='" + this.tid + "', bTid=" + Arrays.toString(this.bTid) + ", userdata='" + this.userdata + "', bUser=" + Arrays.toString(this.bUser) + ", reserved='" + this.reserved + "', bRes=" + Arrays.toString(this.bRes) + ", childAntId=" + this.childAntId + ", strUtc='" + this.strUtc + "', frequencyPoint=" + this.frequencyPoint + ", phase=" + this.phase + ", dateFormat=" + this.dateFormat + ", epcData='" + this.epcData + "', bEpcData=" + Arrays.toString(this.bEpcData) + ", ctesiusLtu27=" + this.ctesiusLtu27 + ", ctesiusLtu31=" + this.ctesiusLtu31 + ", readerSerialNumber='" + this.readerSerialNumber + "', replySerialNumber=" + this.replySerialNumber + ", kunYue=" + this.kunYue + ", rssidBm=" + this.rssidBm + ", crc=" + this.crc + ", EPC_2V2_challenge='" + this.EPC_2V2_challenge + "', EPC_2V2_tag_response='" + this.EPC_2V2_tag_response + "'}";
    }

    public String toHexString() {
        return "HexString{" + HexUtils.bytes2HexString(this.cData) + '}';
    }
}
