void added_script()
{
    /*GUI::displayMessage(GUI::getKeyBinding(GUI::PA::FIRE) + GUI::getKeyBinding(GUI::PA::ACCEL) + "This trigger was added by another script");
    jumpKartTo( 0, 67.90, 99.49 );
    Vec3 a;
    Vec3 b;
    b=a;
    Vec3 c = Vec3();
    Vec3 d = Vec3(2,3,0);
    printVec3(d); */
}


void tutorial_bananas()
{
    GUI::displayMessage(GUI::translate("Avoid bananas!"));
    Karts::squashKart(0, 5.0); //id of kart,time to squash
    //teleportKart(0, Vec3(0,0,0)); //id of kart, x,y,z
    //setVelocity(0, Vec3(5, 50 , 8)); //id of kart, velocity 								//components x,y,z

}

void tutorial_drive()
{
    //array<string> arr = { "Foo", "Bar", "Foobar" };
    //GUI::STK_ArrayTest(arr);
    GUI::displayMessage(
        GUI::translate("Accelerate with <%s> and steer with <%s> and <%s>",
            GUI::getKeyBinding(GUI::PA::ACCEL),
            GUI::getKeyBinding(GUI::PA::STEER_LEFT),
            GUI::getKeyBinding(GUI::PA::STEER_RIGHT)
        )
    );
}

void tutorial_giftboxes()
{
    GUI::displayMessage(GUI::translate("Collect gift boxes, and fire the weapon with <%s> to blow away these boxes!", GUI::getKeyBinding(GUI::PA::FIRE)));
}

void tutorial_backgiftboxes()
{
    GUI::displayMessage(
        GUI::translate("Press <%s> to look behind. Fire the weapon with <%s> while pressing <%s> to fire behind!",
            GUI::getKeyBinding(GUI::PA::LOOK_BACK),
            GUI::getKeyBinding(GUI::PA::FIRE),
            GUI::getKeyBinding(GUI::PA::LOOK_BACK)
        )
    );
}

void tutorial_nitro_use()
{
    GUI::displayMessage(GUI::translate("Use the nitro you collected by pressing <%s>!", GUI::getKeyBinding(GUI::PA::NITRO)));
}

void tutorial_nitro_collect()
{
    GUI::displayMessage(GUI::translate("Collect nitro bottles (we will use them after the curve)"));
}

void tutorial_rescue()
{
    GUI::displayMessage(GUI::translate("Oops! When you're in trouble, press <%s> to be rescued", GUI::getKeyBinding(GUI::PA::RESCUE)));
}

void tutorial_skidding()
{
    GUI::displayMessage(
        GUI::translate("Accelerate and press the <%s> key while turning to skid. Skidding for a short while can help you turn faster to take sharp turns.",
            GUI::getKeyBinding(GUI::PA::DRIFT)
        )
    );
}

void tutorial_skidding2()
{
    GUI::displayMessage(GUI::translate("Note that if you manage to skid for several seconds, you will receive a bonus speedup as a reward!"));
}

void tutorial_endmessage()
{
    GUI::displayMessage(GUI::translate("You are now ready to race. Good luck!"));
}

