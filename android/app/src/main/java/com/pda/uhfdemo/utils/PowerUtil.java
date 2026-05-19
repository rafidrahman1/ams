package com.pda.uhfdemo.utils;

import android.util.Log;
import java.io.FileWriter;

/* JADX INFO: loaded from: classes.dex */
public class PowerUtil {
    private static String s2 = "/proc/gpiocontrol/set_uhf";
    private static String s3 = "/proc/gpiocontrol/set_bd";

    public static void power(String str) {
        try {
            FileWriter fileWriter = new FileWriter(s2);
            fileWriter.write(str);
            fileWriter.close();
            Log.e("PowerUtil", "power=" + str + " Path=" + s2);
            Thread.sleep(300L);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
