package com.angi.day.common.id;

import java.security.SecureRandom;

public final class Ulid {
    private static final char[] ENC = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".toCharArray();
    private static final SecureRandom RNG = new SecureRandom();

    private Ulid() {}

    public static String generate() {
        long time = System.currentTimeMillis();
        char[] out = new char[26];
        // 10 chars of timestamp (base32), most significant first
        for (int i = 9; i >= 0; i--) {
            out[i] = ENC[(int) (time & 31)];
            time >>>= 5;
        }
        // 16 chars of randomness
        for (int i = 10; i < 26; i++) {
            out[i] = ENC[RNG.nextInt(32)];
        }
        return new String(out);
    }

    public static String generate(String prefix) {
        return prefix + generate();
    }
}
