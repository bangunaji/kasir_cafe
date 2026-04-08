allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    fun overrideAndroidNamespace() {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                android.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(android, 34)
            } catch (e: Exception) {
                try {
                    android.javaClass.getMethod("setCompileSdk", Int::class.java).invoke(android, 34)
                } catch (e2: Exception) {}
            }
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val namespace = getNamespace.invoke(android)
                if (namespace == null || namespace.toString().isEmpty()) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    var groupString = project.group.toString()
                    if (groupString.isEmpty()) {
                        groupString = "com.kasir.plugin_" + project.name.replace("-", "_")
                    }
                    setNamespace.invoke(android, groupString)
                }
            } catch (e: Exception) {
            }
        }
    }

    if (project.state.executed) {
        overrideAndroidNamespace()
    } else {
        project.afterEvaluate {
            overrideAndroidNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
