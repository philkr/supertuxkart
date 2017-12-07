from pykart import Kart
from time import sleep, time
from random import random

t0 = time()
K = Kart("lighthouse", 300, 200)
t1 = time()
K.restart()
t2 = time()
print( K.waitRunning() )
t3 = time()
print( K.running, t1-t0, t2-t1, t3-t2 )

im, lbl = None, None
action = 0
for i in range(10000):
	state, obs = K.step(action)
	action = state['ai_action']
	sleep(0.01)
	
	#print( state, action )
	#from pylab import *
	#ion()
	##figure()
	##subplot(1,2,1)
	#if obs is not None:
		#if im is None:
			#im = imshow(obs)
		#else:
			#im.set_data(obs)
	#draw()
	#pause(0.001)
