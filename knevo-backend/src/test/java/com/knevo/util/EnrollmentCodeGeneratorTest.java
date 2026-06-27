package com.knevo.util;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;
import java.util.function.Predicate;

import static org.junit.jupiter.api.Assertions.*;

class EnrollmentCodeGeneratorTest {

    private final EnrollmentCodeGenerator generator = new EnrollmentCodeGenerator();

    @Test
    void generateProducesEightCharsFromTheSafeAlphabet() {
        String allowed = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        for (int i = 0; i < 100; i++) {
            String code = generator.generate();
            assertEquals(8, code.length(), "code must be 8 chars");
            for (char c : code.toCharArray()) {
                assertTrue(allowed.indexOf(c) >= 0, "unexpected char: " + c);
            }
        }
    }

    @Test
    void generateUniqueReturnsImmediatelyWhenNoCollision() {
        String code = generator.generateUnique(c -> false);
        assertEquals(8, code.length());
    }

    @Test
    void generateUniqueReRollsPastExistingCodes() {
        // First two generated codes are "taken"; the third must be returned.
        Set<String> taken = new HashSet<>();
        Predicate<String> exists = c -> {
            if (taken.size() < 2) {
                taken.add(c);
                return true; // collide on the first two
            }
            return false;
        };
        String code = generator.generateUnique(exists);
        assertFalse(taken.contains(code), "must not return a code reported as existing");
    }

    @Test
    void generateUniqueThrowsWhenEveryCandidateCollides() {
        // Predicate always reports a collision -> exhausts the re-roll budget.
        assertThrows(IllegalStateException.class, () -> generator.generateUnique(c -> true));
    }
}
