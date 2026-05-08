package com.ntt.recon.support;

public final class MqExceptionClassifier {
    private MqExceptionClassifier() {
    }

    public static boolean isMqrc2035(Throwable throwable) {
        Throwable current = throwable;
        while (current != null) {
            String message = current.getMessage();
            if (message != null) {
                String normalized = message.toUpperCase();
                if (normalized.contains("MQRC 2035")
                        || normalized.contains("MQRC_NOT_AUTHORIZED")
                        || normalized.contains("NOT AUTHORIZED")
                        || normalized.contains("JMSCMQ0001")
                        || normalized.contains("2035")) {
                    return true;
                }
            }
            current = current.getCause();
        }
        return false;
    }
}
