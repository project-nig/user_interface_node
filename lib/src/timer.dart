import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'parameters.dart';
 
StopWatchTimer stopWatchTimer = StopWatchTimer(
      mode: StopWatchMode.countDown,
      );

startTimer(prefs) {

  var lastUnstoppedTimerDuration=0;
  if (prefs.containsKey('timerStartTime')) {
      lastUnstoppedTimerDuration = prefs.getInt('timerStartTime');
      prefs.remove('timerStartTime');
    }
  ResetTimer(lastUnstoppedTimerDuration);
}

ResetTimer(duration) {
  //duration is in mSec
  stopWatchTimer.setPresetTime(mSec: duration,add:false);
  stopWatchTimer.onResetTimer();
  stopWatchTimer.onStartTimer();
}

Future<String> CheckTimer(duration) async{
  if (timer_check_flag==true){
    if (stopWatchTimer.rawTime.value==0){
      ResetTimer(duration);
      return "ok";
    }
    var result=stopWatchTimer.rawTime.value;
    var wait_time=result/1000;
    return wait_time.round().toString();
  }
  else{
    return "ok";
  }
}
    
DisposeTimer(prefs) async {
  var lastUnstoppedTimerDuration=stopWatchTimer.rawTime.value;
   prefs.setInt('timerStartTime', lastUnstoppedTimerDuration);
  //stopWatchTimer.dispose();
}