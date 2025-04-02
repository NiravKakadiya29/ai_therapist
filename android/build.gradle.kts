//// Top-level build file where you can add configuration options common to all sub-projects/modules.
//import org.gradle.api.tasks.Delete
//import org.gradle.api.file.Directory
//
//allprojects {
//    repositories {
//        google()
//        mavenCentral()
//        maven { url = uri("https://maven.google.com") } // Ensure Firebase repository is added
//    }
//}
//
//val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
//rootProject.layout.buildDirectory.value(newBuildDir)
//
//subprojects {
//    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//    project.layout.buildDirectory.value(newSubprojectBuildDir)
//}
//subprojects {
//    project.evaluationDependsOn(":app")
//}
//
//tasks.register<Delete>("clean") {
//    delete(rootProject.layout.buildDirectory)
//}
//
//// REMOVE dependencyResolutionManagement from here ❌
//
//buildscript {
//    repositories {
//        google()
//        mavenCentral()
//    }
//    dependencies {
//        classpath("com.google.gms:google-services:4.3.10") // Firebase Plugin
//        classpath("com.android.tools.build:gradle:8.1.0") // Latest Gradle Plugin
//    }
//}


// Top-level build file where you can add configuration options common to all sub-projects/modules.
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// All projects (including app) will use this repository configuration
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.google.com") } // Ensure Firebase repository is added
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app") // Ensures all subprojects depend on the 'app' module
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory) // Cleanup task to delete build directory
}

// Define classpaths for dependencies and plugins
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Firebase Google Services plugin for Firebase Authentication, Sign-In, etc.
        classpath("com.google.gms:google-services:4.3.10") // Firebase Plugin for Google Sign-In, Firebase Auth
        // Gradle plugin for Android projects
        classpath("com.android.tools.build:gradle:8.1.0") // Android Gradle Plugin (latest version)
    }
}

