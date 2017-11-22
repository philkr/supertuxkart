#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <boost/interprocess/sync/interprocess_mutex.hpp>
#include <boost/interprocess/sync/interprocess_condition.hpp>
#include <boost/interprocess/sync/scoped_lock.hpp>
#include <boost/filesystem.hpp>

#include <boost/python.hpp>
#include <numpy/arrayobject.h>
#include <signal.h>
#include <unistd.h>
#include <unordered_set>
#include <vector>
#ifdef __linux__
#include <sys/prctl.h>
#endif

namespace ip = boost::interprocess;
namespace bp = boost::python;

#include "../src/pykart_controller.h"

struct TuxComm {
	std::string shmem_name;
	ip::shared_memory_object shmem;
	ip::mapped_region region;
	TuxComm(const std::string & name, bool owning): shmem_name(name){
		if (owning) {
			shmem = ip::shared_memory_object(ip::create_only, name.c_str(), ip::read_write);
			shmem.truncate(sizeof(PyKartController) + 100);
		} else {
			shmem = ip::shared_memory_object(ip::open_only, name.c_str(), ip::read_write);
		}
		region = ip::mapped_region(shmem, ip::read_write, 0, sizeof(PyKartController) + 100);
	}
	~TuxComm() {
		region = ip::mapped_region();
		ip::shared_memory_object::remove(shmem_name.c_str());
	}
	operator PyKartController *() {
		return (PyKartController*)region.get_address();
	}
	operator const PyKartController *() const {
		return (PyKartController*)region.get_address();
	}
	const PyKartController * get() const {
		return (PyKartController*)region.get_address();
	}
	PyKartController * get() {
		return (PyKartController*)region.get_address();
	}
};
template<bool flip, typename T> void cp(T* out, const T * in, size_t H, size_t W) {
	if (flip) {
		for(size_t i=0; i<H; i++)
			cp<false>(out+i*W, in+(H-i-1)*W, 1, W);
	} else {
		memcpy(out, in, W*H*sizeof(T));
	}
}

std::shared_ptr<TuxComm> start(const std::string & track, int W, int H) {
	static int uuid = 1;
	const std::string shmem_name = "pykart" + std::to_string(getpid()) + "_" + std::to_string(uuid++);
	std::shared_ptr<TuxComm> c = std::make_shared<TuxComm>(shmem_name, true);
	{
		PyKartController * sh = *c;
		memset(sh, 0, sizeof(PyKartController));
	}
	
	// Fork and start the game
	pid_t pid = fork();
	if (pid != 0) {
		PyKartController * sh = *c;
		sh->pid = pid;
		return c;
	}
	
#ifdef __linux__
	// Let the child finish if the parent quits
	prctl(PR_SET_PDEATHSIG, SIGTERM);
	// Just making sure we still have a parent
	if (getppid() == 1)
    	exit(1);
#endif
	
	boost::filesystem::path current_path = boost::filesystem::path(__FILE__).remove_filename()/".", tux_path = "build/bin";
	for(auto b = current_path.begin(); b != current_path.end() && !boost::filesystem::is_regular_file(tux_path/"supertuxkart"); b++) {
		tux_path.clear();
		for(auto i=b; i != current_path.end(); i++)
			tux_path /= *i;
	}
	current_path = boost::filesystem::current_path() / "build";
	for(auto b = current_path.begin(); b != current_path.end() && !boost::filesystem::is_regular_file(tux_path/"supertuxkart"); b++) {
		tux_path.clear();
		for(auto i=b; i != current_path.end(); i++)
			tux_path /= *i;
	}
	if (!boost::filesystem::is_regular_file(tux_path/"supertuxkart"))
		printf("ERROR: supertuxkart executable not found in '%s'! Please copy it into the 'pykart' directory or the current working directory", tux_path.string().c_str());
	std::vector<const char *> envp;// = {"SUPERTUX2_DATA_DIR=./data/"};
	for( int i=0; environ[i]; i++ )
		envp.push_back(environ[i]);
	envp.push_back(nullptr);
	execle((tux_path/"supertuxkart").c_str(), "supertuxkart", ("--shmem="+shmem_name).c_str(), "-w", ("-t="+track).c_str(), ("-s="+std::to_string(W)+"x"+std::to_string(H)).c_str(), "-R", "--log=3", NULL, envp.data());
	((PyKartController *)TuxComm(shmem_name, false))->quit = 1;
	printf("Exec failed, giving up!\n");
	// exec never returns
	_exit(EXIT_FAILURE);
}
static std::unordered_set<pid_t> kill_list;
void killAll() {
	for( pid_t pid: kill_list )
		kill(pid, SIGKILL);
}

class Kart {
protected:
	std::shared_ptr<TuxComm> c;
	Kart(const Kart&) = delete;
	Kart& operator=(const Kart&) = delete;
public:
	Kart(const std::string & level, int W, int H) {
		c = start(level, W, H);
		PyKartController * sh = *c;
		if (sh->pid)
			kill_list.insert(sh->pid);
	}
	~Kart() {
		PyKartController * sh = *c;
		quit();
		for(int it=0; it<50 && sh->running; it++) usleep(1000);
		kill(sh->pid, SIGKILL);
	}
	void restart() {
		PyKartController * sh = *c;
		sh->restart = true;
	}
	void quit() {
		PyKartController * sh = *c;
		sh->quit = true;
	}
	bool waitRunning(){
		PyKartController * sh = *c;
		while(!sh->quit && (!sh->running || sh->restart)){ usleep(1000); }

		return sh->running && !sh->restart;
	}
	bool running() {
		PyKartController * sh = *c;
		return sh->running && !sh->restart;
	}
	bp::object step(int32_t action) {
		PyKartController * sh = *c;
		if (sh->running) {
			if (action >= 0)
				for (int i=0; i<8; i++) {
					sh->action_state[i] = !!(action & (1 << i));
				}

			// Let make sure we don't read and write at the same time
			sh->read_lock = 1;
			volatile uint8_t & lk = sh->write_lock; // Let's be paranoid
			while(lk == 1 && sh->running && !sh->quit) {
				if(PyErr_CheckSignals() == -1) {
					sh->quit = 1;
					bp::throw_error_already_set();
				}
				sh->read_lock = 0;
				usleep(50);
				sh->read_lock = 1;
			}
			
			// Fetch the state
			bp::dict state;
			state["position_along_track"] = sh->position_along_track;
			state["distance_to_center"] = sh->distance_to_center;
			state["position_in_race"] = sh->position_in_race;
			state["speed"] = sh->speed;
			state["smooth_speed"] = sh->smooth_speed;
			state["wrongway"] = sh->wrongway;
			state["energy"] = sh->energy;
			state["finish_time"] = sh->finish_time;
			state["angle"] = sh->angle;
			state["timestamp"] = sh->timestamp;
			
			// Fetch the observation
			bp::object obs;
			if (sh->width && sh->height) {
				npy_intp dims[3] = {sh->height, sh->width, 3};
				obs = bp::object(bp::handle<>(PyArray_SimpleNewFromData(3, dims, NPY_UINT8, sh->img_data)));
			}
			sh->read_lock = 0;
			
			return bp::make_tuple(state, obs);
		}
		// Set the next action
		return bp::object();
	}
};

BOOST_PYTHON_MODULE(pykart)
{
	using namespace boost::python;
	import_array1();
	atexit(killAll);
	
	class_<Kart, boost::noncopyable>("Kart", init<std::string, int, int> ((arg("track"),arg("W"),arg("H"))))
	.def("restart", &Kart::restart)
	.def("step", &Kart::step)
	.def("waitRunning", &Kart::waitRunning)
	.def_readonly("running", &Kart::running)
	.def("quit", &Kart::quit);
}
