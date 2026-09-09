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

// FORCE ALL PLUGINS TO USE COMPILE SDK 36 DIRECTLY VIA PROJECT PROPERTIES
subprojects {
    // This forces Flutter's internal build properties for plugins to 36
    project.extra.set("compileSdkVersion", 36)
    
    // This intercepts the extension properties regardless of when they load
    afterEvaluate {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            try {
                // For older plugin formats
                val setCompileSdkVersion = androidExtension.javaClass.getMethod("setCompileSdkVersion", Object::class.java)
                setCompileSdkVersion.invoke(androidExtension, 36)
            } catch (e: Exception) {
                try {
                    // For newer plugin formats
                    val setCompileSdk = androidExtension.javaClass.getMethod("setCompileSdk", Integer::class.java)
                    setCompileSdk.invoke(androidExtension, 36)
                } catch (ex: Exception) {
                    // Fallback configuration if standard methods fail
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
