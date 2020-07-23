'''Defines the `java_binary` rule.
'''

load("@dwtj_rules_java//java:rules/common/CustomJavaInfo.bzl", "CustomJavaInfo")
load("@dwtj_rules_java//java:rules/common/build/build_jar_from_java_sources.bzl", "build_jar_from_java_sources")

def _java_binary_impl(ctx):
    output_jar = build_jar_from_java_sources(ctx)

    return [
        DefaultInfo(
            files = depset([output_jar]),
        ),
        CustomJavaInfo(
            jar = output_jar,
            srcs = depset(ctx.attr.srcs),
            deps = depset(ctx.attr.deps),
        ),
    ]

java_binary = rule(
    implementation = _java_binary_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_empty = False,
            doc = "A list of Java source files whose derived class files should be included in this binary (and any of its dependents).",
            allow_files = [".java"],
        ),
        "main_class": attr.string(
            mandatory = True,
        ),
        "deps": attr.label_list(
            providers = [CustomJavaInfo],
        ),
    },
    toolchains = [
        "@dwtj_rules_java//java/toolchains/java_compiler_toolchain:toolchain_type"
    ],
)
