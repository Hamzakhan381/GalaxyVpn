allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// axevpn_flutter pins NDK 27.0.12077973 for its small JNI helper. Build it with
// the same NDK as the app instead (NDK 28+ also links 16 KB-aligned by default),
// so no extra NDK download is required.
subprojects {
    if (name == "axevpn_flutter") {
        val alignNdk = Action<Project> {
            val appNdk = rootProject.project(":app").extensions
                .getByType(com.android.build.gradle.BaseExtension::class.java).ndkVersion
            extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
                .ndkVersion = appNdk
        }
        if (state.executed) alignNdk.execute(this) else afterEvaluate(alignNdk)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
