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
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
