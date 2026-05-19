package com.gg.reader.api.protocol.gx;

import java.util.Hashtable;

/* JADX INFO: loaded from: classes.dex */
public class LogBaseEpcOver extends Message {
    private String readerSerialNumber;

    public String getReaderSerialNumber() {
        return this.readerSerialNumber;
    }

    public void setReaderSerialNumber(String str) {
        this.readerSerialNumber = str;
    }

    @Override // com.gg.reader.api.protocol.gx.Message
    public void ackUnpack() {
        if (this.cData == null || this.cData.length <= 0) {
            return;
        }
        Hashtable<Byte, String> hashtable = new Hashtable<Byte, String>() { // from class: com.gg.reader.api.protocol.gx.LogBaseEpcOver.1
            {
                put((byte) 0, "Single operation complete.");
                put((byte) 1, "Receive stop instruction.");
                put((byte) 2, "A hardware failure causes an interrupt.");
            }
        };
        if (this.cData == null || this.cData.length != 1) {
            return;
        }
        setRtCode(this.cData[0]);
        if (hashtable.containsKey(Byte.valueOf(this.cData[0]))) {
            setRtMsg(hashtable.get(Byte.valueOf(this.cData[0])));
        }
    }

    public String toString() {
        return "LogBaseEpcOver{readerSerialNumber='" + this.readerSerialNumber + "'}";
    }
}
