'''Defines the `JavaCompilationInfo` provider.
'''

# TODO(dwtj): Redesign `build_jar_from_java_sources(ctx)` to take an instance of this provider.
JavaCompilationInfo = provider(
    doc = "Describes the inputs, outputs, and options of a Java compiler invocation for a particular Java target.",
    fields = {
        "srcs": "A depset of the Java source `File`s directly included in a Java target. (This does not include either generated or transitive Java sources). This may be `None`. (E.g., a `java_import` target may not have any source files.).",
        "class_path_jars": "A depset of JAR `File`s to be included on the class-path during this compilation.",
        "class_files_output_jar": "A `File` pointing to the JAR of class files generated by this Java compilation action.",
        # TODO(dwtj): Consider supporting compiler plugins
        # TODO(dwtj): Consider supporting "generated_sources_output_jar".
        # TODO(dwtj): Consider supporting "native_headers_archive" (i.e. `javac -h <directory>).
        # TODO(dwtj): Consider supporting Java source code version checks.
    },
)