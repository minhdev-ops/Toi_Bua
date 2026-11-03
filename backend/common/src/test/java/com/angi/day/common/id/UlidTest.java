package com.angi.day.common.id;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class UlidTest {

    @Test
    void generates_26_char_unique_ids() {
        String a = Ulid.generate();
        String b = Ulid.generate();
        assertEquals(26, a.length());
        assertNotEquals(a, b);
    }

    @Test
    void prefixes_id_with_domain_prefix() {
        String p = Ulid.generate("spn_");
        assertTrue(p.startsWith("spn_"));
        assertEquals(4 + 26, p.length());
    }
}
