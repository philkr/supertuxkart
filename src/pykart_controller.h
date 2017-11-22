#pragma once

#include <cstddef>
const size_t MAX_SIZE = 1024;

struct PyKartController {
    int pid = 0;
    unsigned char read_lock=0, write_lock=0;
	bool running = false, racing = false, restart = false, restarted = false, quit = false;
	unsigned char action_state[8] = {0};
	float timestamp, position_along_track, distance_to_center, angle;
	float position_in_race;
	float speed, smooth_speed, wrongway, energy, finish_time;
	int height, width;
	unsigned char img_data[MAX_SIZE*MAX_SIZE*3];
};
