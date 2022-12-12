abstract class AppStates {}

class InitialAppState extends AppStates {
}

class LoadingAppState extends AppStates {
}

class GotLocationAppState extends AppStates {}
class GotPrayerTimesAppState extends AppStates {}

class ToggleIconAppState extends AppStates {}
class PlaySoundAppState extends AppStates {}
class PauseSoundAppState extends AppStates {}
class ChangeQuranSoundActiveState extends AppStates {}
class SetCurrentPageNumberAppState extends AppStates {}

class ErrorAppState extends AppStates {}
