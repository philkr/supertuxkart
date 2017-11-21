namespace stklib_monkeyCheering_a
{
    void throwBanana(int kart_id, const string instance_id,
                     const string library_name)
    {
        Track::Mesh@ mesh = Track::getTrackObject(instance_id, library_name)
            .getMesh();
        // For disabled animated scenery
        if (mesh !is null)
        {
            if (mesh.getAnimationSet() != 3)
            {
                // This monkey is not using banana animation set, disable the
                // trigger for this round of game
                Track::setTriggerReenableTimeout("banana_trigger", instance_id,
                    999999.0/*reenable_time*/);
                return;
            }
            mesh.setFrameLoopOnce(214, 269);
        }
    }
}
