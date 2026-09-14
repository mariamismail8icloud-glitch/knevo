package com.knevo.util;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.util.function.Predicate;

@Component
public class EnrollmentCodeGenerator {
    private static final String CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int LENGTH = 8;
    /** Re-roll budget when a freshly generated code already exists. The 32^8
     * keyspace makes even one collision astronomically unlikely, so a handful
     * of attempts is plenty before we surface a hard failure. */
    private static final int MAX_ATTEMPTS = 10;
    private final SecureRandom random = new SecureRandom();

    public String generate() {
        StringBuilder sb = new StringBuilder(LENGTH);
        for (int i = 0; i < LENGTH; i++) {
            sb.append(CHARS.charAt(random.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    /**
     * Generate a code that no existing patient holds. {@code exists} is the
     * collision check (e.g. {@code userRepository::existsByEnrollmentCode}).
     * The DB UNIQUE constraint remains the ultimate guard against the rare
     * check-then-insert race; this just stops a collision from ever producing
     * a failed signup in practice.
     */
    public String generateUnique(Predicate<String> exists) {
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            String code = generate();
            if (!exists.test(code)) {
                return code;
            }
        }
        throw new IllegalStateException("Unable to generate a unique enrollment code after " + MAX_ATTEMPTS + " attempts");
    }
}
