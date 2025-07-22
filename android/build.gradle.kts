allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Note: Google Services classpath not needed when using direct OAuth configuration
// buildscript {
//     dependencies {
//         classpath("com.google.gms:google-services:4.4.2")
//     }
// }

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
