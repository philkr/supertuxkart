void onStart()
{
    Utils::logInfo("ScriptingCallback: onStart");
}

void onBoxHitByItem(int itemType, int idKart, const string objID)
{
    // Test
    Utils::logInfo("ScriptingCallback: onBoxHitByItem. Item = " + itemType + "; idKart = " + idKart + "; objID = " + objID);
}

void onKartKartCollision(int idKart1, int idKart2)
{
    // Test
    Utils::logInfo("ScriptingCallback: onKartKartCollision: " + idKart1 + " - " + idKart2);
}

void tutorial_drive(int idKart)
{
    GUI::displayModalMessage(
        GUI::translate("Accelerate with <%s>, and steer with <%s> and <%s>.",
            GUI::getKeyBinding(GUI::PlayerAction::ACCEL),
            GUI::getKeyBinding(GUI::PlayerAction::STEER_LEFT),
            GUI::getKeyBinding(GUI::PlayerAction::STEER_RIGHT)
        )
    );
}


void tutorial_bananas(int idKart)
{
    GUI::displayModalMessage(GUI::translate("Avoid bananas!"));
}

void tutorial_giftboxes(int idKart)
{
    GUI::displayModalMessage(GUI::translate("Collect gift boxes, and fire the weapon with <%s> to blow away these boxes!", GUI::getKeyBinding(GUI::PlayerAction::FIRE)));
}

void tutorial_backgiftboxes(int idKart)
{
    GUI::displayModalMessage(
        GUI::translate("Press <%s> to look behind. Fire the weapon with <%s> while pressing <%s> to fire behind!",
            GUI::getKeyBinding(GUI::PlayerAction::LOOK_BACK),
            GUI::getKeyBinding(GUI::PlayerAction::FIRE),
            GUI::getKeyBinding(GUI::PlayerAction::LOOK_BACK)
        )
    );
}

void tutorial_nitro_use(int idKart)
{
    GUI::displayModalMessage(GUI::translate("Use the nitro you collected by pressing <%s>!", GUI::getKeyBinding(GUI::PlayerAction::NITRO)));
}

void tutorial_nitro_collect(int idKart)
{
    GUI::displayModalMessage(GUI::translate("Collect nitro bottles (we will use them after the curve)."));
}

void tutorial_rescue(int idKart)
{
    GUI::displayModalMessage(GUI::translate("Oops! When you're in trouble, press <%s> to be rescued.", GUI::getKeyBinding(GUI::PlayerAction::RESCUE)));
}

void tutorial_skidding(int idKart)
{
    GUI::displayModalMessage(
        GUI::translate("Accelerate and press the <%s> key while turning to skid. Skidding for a short while can help you turn faster to take sharp turns.",
            GUI::getKeyBinding(GUI::PlayerAction::DRIFT)
        )
    );
}

void tutorial_skidding2(int idKart)
{
    GUI::displayModalMessage(GUI::translate("Note that if you manage to skid for several seconds, you will receive a bonus speedup as a reward!"));
}

void tutorial_endmessage(int idKart)
{
    GUI::displayModalMessage(GUI::translate("You are now ready to race. Good luck!"));
}

void tutorial_exit(int idKart)
{
    Track::exitRace();
}


// ============= DEBUG TESTS ==============
void debug_squash()
{
    int idKart = 0;
    Utils::logInfo("Testing squash");
    Kart::squash(idKart, 5.0);
}

void debug_set_velocity()
{
    int idKart = 0;
    Utils::logInfo("Testing setVelocity");
    Kart::setVelocity(idKart, Vec3(0, 10, 0));
}

// TODO: teleport doesn't work very well
void debug_teleport()
{
    int idKart = 0;
    Utils::logInfo("Testing getLocation + teleport");
    Vec3 loc = Kart::getLocation(idKart);
    Utils::logInfo(Utils::insertValues("Kart %s location : %s %s %s", idKart + "", loc.getX() + "", loc.getY() + "", loc.getZ() + ""));
    Kart::teleport(idKart, Vec3(loc.getX() - 3, loc.getY(), loc.getZ() - 3));
}
