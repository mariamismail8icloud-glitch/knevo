1. The Mobile application talks to the ESP32-S3 Over Bluetooth first, Through that connection, it configure is the Wi-Fi connection in the ESP32-S3, Allowing the rest of the communication to take place over WIFI. The beta is relate to the Mobile application as early as possible, but it is buffered to decouple Data capture from relaying the data Mobile application. Travel can be a couple of seconds delay at any point in time.
2. When the doctor is a configuration it proper it is first stored in the back end then it is relate to the Mobile application of the patient and From from there it gets relate to the Device over Bluetooth The first time the patient starts to use the device.
3. The exoskeleton Has 3 IMU(s) and 2 FSR(s), So it measures things like knee angle and gait event events.
4. A session is a therapy session basically of the patient using the device they started from their Mobile application and the ended from their Mobile application as well based on Dr guidance in terms of schedule.
5. Weather patient and doctors existed the same system of different trolls are completely separate user basis is a decision that needs to be taken however Patience are not expected to access the web application and doctors are not expected to access the Mobile applications. Yet both of them exist as entities represented in the backend. There can possibly be a single admin role that enrolled doctors that does not need to be a representation of individual clinics.
6. The patient self registers from their Mobile app. The patient convention generate an enrolment code from the Mobile application and share it with their doctor. The doctor can then enroll them using that code.
7. The Mobile app is currently built in react native, we think. However, it is worth understanding that whatever code or decisions that have been made are open for change if that will make it faster to get to the finish line.
8. The backend is currently Fire base. And again, the same note as above. With tendency to switch to Java Spring Boot and PostgreSQL for the database.
9. Web app in React
10. Keep it simple; Single clinic
11. No constraints from legal perspective. However, even in a graduation project it is useful to have reasonable answers regarding privacy.
12. max speed, max range of motion, session duration, and frequency and schedule.
13. All the above. (raw sensor graphs, aggregated stats per session, progress trends across sessions)
14. In case of temp WiFi connectivity loss, the data is buffered on device and sent to mobile app once connectivity is restored. The mobile app doesn't need to be present during the session, it is only needed during session start and stop.
