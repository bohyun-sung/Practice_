import java.time.Duration;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

public class time {
     public static void main(String[] args) throws InterruptedException {
        boolean isStop = true;
        long start = System.currentTimeMillis();

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm:ss");
        while (isStop) {
            long current = System.currentTimeMillis();
            long elapsedMillis = current - start;
            
            Duration duration = Duration.ofMillis(elapsedMillis);

            LocalTime time = LocalTime.MIN.plus(duration);

            String formatterdTime = time.format(formatter);

            System.out.println("경과 시간: " + formatterdTime);
            Thread.sleep(1000L);
        }

    }
    
}