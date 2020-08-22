'''Defines the `javadoc_aspect`. It runs the `javadoc` exec on Java `srcs`.
'''

load("@dwtj_rules_java//java:providers/JavaCompilationInfo.bzl", "JavaCompilationInfo")
load("@dwtj_rules_java//java:rules/common/actions/write_class_path_args_file.bzl", "write_compile_time_class_path_args_file")

def _to_path(file):
    '''Used as a map function to convert a file to its short path.
    '''
    return file.path

JavadocAspectInfo = provider(
    fields = {
        'doclint_log': "The doclint log `File` generated by `javadoc`. This will be `None` if the target doesn't include any usable Java sources.",
        'html_archive': "The archive `File` of HTML files generated by `javadoc`. This will be `None` if the target doesn't include any usable Java sources."
    }
)

def _extract_class_path_separator(aspect_ctx):
    return aspect_ctx.toolchains['@dwtj_rules_java//java/toolchains/javadoc_toolchain:toolchain_type'] \
        .javadoc_toolchain_info \
        .class_path_separator

def _extract_javadoc_executable(aspect_ctx):
    return aspect_ctx.toolchains['@dwtj_rules_java//java/toolchains/javadoc_toolchain:toolchain_type'] \
        .javadoc_toolchain_info \
        .javadoc_executable

def _javadoc_aspect_impl(target, aspect_ctx):
    # Skip a target if it doesn't provide a `JavaCompilationInfo`.
    if JavaCompilationInfo not in target:
        return JavadocAspectInfo(
            doclint_log = None,
            html_archive = None,
        )
    
    # Extract some information from the environment for brevity.
    name = target.label.name
    path_prefix = name + ".javadoc_aspect/"
    actions = aspect_ctx.actions
    srcs = target[JavaCompilationInfo].srcs
    srcs_args_file = target[JavaCompilationInfo].srcs_args_file
    class_path_jars = target[JavaCompilationInfo].class_path_jars
    javadoc_exec = _extract_javadoc_executable(aspect_ctx)

    # Declare outputs.
    html_archive = actions.declare_file(name + ".javadoc.tar.gz")
    doclint_log = actions.declare_file(path_prefix + name + ".javadoc.doclint.log")

    # Declare temporaries.
    run_javadoc_script = actions.declare_file(path_prefix + name + ".run_javadoc.sh")
    html_temp_directory = actions.declare_directory(path_prefix + name + ".javadoc.html.temp")

    # Create a class path args file.
    # TODO(dwtj): A similar args files should be made by the target rule.
    #  Consider re-using that one instead of re-creating it here.
    class_path_args_file = write_compile_time_class_path_args_file(
        name = path_prefix + name + ".javadoc_class_path.args",
        jars = class_path_jars,
        actions = actions,
        class_path_separator = _extract_class_path_separator(aspect_ctx),
    )

    # Create the run script.
    actions.expand_template(
        template = aspect_ctx.file._run_javadoc_script_template,
        output = run_javadoc_script,
        substitutions = {
            "{JAVADOC_EXECUTABLE}": javadoc_exec.path,
            "{CLASS_PATH_ARGS_FILE}": class_path_args_file.path,
            "{JAVA_SOURCE_ARGS_FILE}": srcs_args_file.path,
            "{HTML_TEMP_DIRECTORY}": html_temp_directory.path,
            "{HTML_ARCHIVE_FILE}": html_archive.path,
            "{JAVADOC_LINT_LOG_FILE}": doclint_log.path,
        }
    )

    # Run the run script.
    actions.run(
        executable = run_javadoc_script,
        outputs = [
            doclint_log,
            html_archive,
            html_temp_directory,
        ],
        tools = [
            javadoc_exec,
        ],
        inputs = depset(
            direct = [
                class_path_args_file,
                srcs_args_file,
            ],
            transitive = [
                srcs,
                class_path_jars,
            ],
        ),
        mnemonic = "Javadoc",
        progress_message = "Linting and compiling Javadoc for Java target {}".format(target.label),
        use_default_shell_env = False,
    )

    return [
        OutputGroupInfo(default = [
            doclint_log,
            html_archive
        ]),
        JavadocAspectInfo(
            doclint_log = doclint_log,
            html_archive = html_archive
        ),
    ]

javadoc_aspect = aspect(
    implementation = _javadoc_aspect_impl,
    provides = [
        JavadocAspectInfo,
    ],
    attrs = {
        "_run_javadoc_script_template": attr.label(
            default = Label("@dwtj_rules_java//java:aspects/javadoc_aspect/TEMPLATE.run_javadoc.sh"),
            allow_single_file = True,
        )
    },
    toolchains = [
        "@dwtj_rules_java//java/toolchains/javadoc_toolchain:toolchain_type",
    ],
)
