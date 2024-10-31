plugins {
    kotlin("jvm") version "1.8.20"
    application
}

group = "com.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation(kotlin("stdlib"))

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.1")

    // JavaCV dependencies
    implementation("org.bytedeco:javacv-platform:1.5.9")
    implementation("org.bytedeco:ffmpeg-platform:5.1.2-1.5.9")
    implementation("org.bytedeco:opencv-platform:4.7.0-1.5.9")

    // Logging
    implementation("ch.qos.logback:logback-classic:1.4.7")
    implementation("io.github.microutils:kotlin-logging:3.0.5")

    // CLI parsing
    implementation("com.github.ajalt.clikt:clikt:3.5.2")

    // Testing
    testImplementation("org.junit.jupiter:junit-jupiter:5.9.2")
    testImplementation("io.mockk:mockk:1.13.5")
}

application {
    mainClass.set("com.example.MainKt")
}

tasks.test {
    useJUnitPlatform()
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions.jvmTarget = "17"
}