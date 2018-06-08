FROM swift
COPY ./Sources Sources
COPY ./Tests Tests
COPY ./Package.swift Package.swift
RUN swift package update
RUN swift package edit Core --revision fluent-gm
CMD swift test
