package com.angi.day.common.page;

import java.util.List;

public record CursorPage<T>(List<T> items, PageMeta page) {}
