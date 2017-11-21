void onStart()
{
    // Disable water flooding when there's AI karts because they can't handle it
    int karts = Track::getNumberOfKarts();
    int players = Track::getNumLocalPlayers();
    
    if (karts > players)
    {
        Track::TrackObject@ water = Track::getTrackObject("", "water");
        Track::Animator@ animator = water.getIPOAnimator();
        animator.setPaused(true);
        
        Track::TrackObject@ waterfall = Track::getTrackObject("", "waterfall");
        Track::Animator@ animator2 = waterfall.getIPOAnimator();
        animator2.setPaused(true);
        
        Track::TrackObject@ waterdeath = Track::getTrackObject("", "waterdeath");
        Track::Animator@ animator3 = waterdeath.getIPOAnimator();
        animator3.setPaused(true);
    }
}
