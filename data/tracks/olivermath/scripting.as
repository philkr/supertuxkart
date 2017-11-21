bool isEasterEgg(Track::TrackObject@ obj)
{
    // enum RaceManager::MINOR_MODE_EASTER_EGG is 3000
    return Track::getMinorRaceMode() == 3000;
}
