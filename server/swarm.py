# Adapted from boids implementation by Stephen Chappell
# Accessed on 11/20/2012 at http://code.activestate.com/recipes/502240/
# Which was in turn motivated by the following pseudocode:
# http://www.vergenet.net/~conrad/boids/pseudocode.html

# Note: OSC messages (incoming and outgoing) are
#       normalized to the range 0-1

import random           # FOR RANDOM BEGINNINGS
#from Tkinter import *   # ALL VISUAL EQUIPMENT
import socket, OSC      # OSC COMMUNICATION
import time, threading
import math

DIMLIMIT = 700          # LIMIT OF DIMENSION VALUES
WIDTH = DIMLIMIT        # OF SCREEN IN PIXELS
HEIGHT = DIMLIMIT       # OF SCREEN IN PIXELS
BOIDS = 19              # IN SIMULATION
BOIDMASS = 2            # IN SIMULATION
BLIMIT = 30             # LIMIT FOR BOID PERCEPTION
ATTRACTORS = 1          # IN SIMULATION
ATTRACTION = 6          # ATTRACTOR INFLUENCE
WALL = 100              # FROM SIDE IN PIXELS
WALL_FORCE = 30         # ACCELERATION PER MOVE
UPPER_SPEED_LIMIT = 6000      # FOR BOID VELOCITY
SPEED_LIMIT = 1000      # FOR BOID VELOCITY
BOID_RADIUS = 3         # FOR BOIDS IN PIXELS
ATTRACTOR_RADIUS = 5    # FOR BOIDS IN PIXELS
OFFSET_START = 20       # FROM WALL IN PIXELS
FRAMES_PER_SEC = 40     # SCREEN UPDATE RATE
UPDATE_TIME = 500 / FRAMES_PER_SEC
NDIMS = 6               # MULTIDIMENSIONAL SWARM SPACE

# FOR OSC
RECEIVE_ADDRESS = ('127.0.0.1', 9000) # tupple with ip, port.
SUPERCOLLIDER_ADDRESS = ('127.0.0.1', 57120) # SuperCollider on local machine.
PROCESSING_ADDRESS = ('127.0.0.1', 57121) # Processing on local machine.

# FOR CREATING/SENDING NOTE EVENTS
MAXFREQ = 90 #MIDI FREQ
MINFREQ = 20
MAXAMP = 0.9
MAXDUR = 180
MINDUR = 1
MAXIOI = 150
MINIOI = 1
FREQSCALER = float(MAXFREQ - MINFREQ) / float(DIMLIMIT)
AMPSCALER = float(MAXAMP) / float(DIMLIMIT)
DURSCALER = float(MAXDUR - MINDUR) / float(DIMLIMIT)
IOISCALER = float(MAXIOI - MINIOI) / float(DIMLIMIT)

# OSC clients
# SuperCollider
scClient = OSC.OSCClient()
scClient.connect( SUPERCOLLIDER_ADDRESS ) # note that the argument is a tupple and not two arguments

pClient = OSC.OSCClient()
pClient.connect( PROCESSING_ADDRESS )




import threading

class Timer(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.event = threading.Event()

    def run(self):
        while not self.event.is_set():
            move();
            makesound();
            self.event.wait(float(UPDATE_TIME) / 1000)

    def stop(self):
        self.event.set()


################################################################################

def main():
    # Start the program.
    initialise()
    #mainloop()
    
    tmr = Timer()
    tmr.start()
 
def initialise():
    # Setup simulation variables.
    global sim_time  # discreet simulation time variable
    sim_time = 0     # start at 0
    global note_time # time of next note
    note_time = 0    # start at zero - see makesound()
    build_boids()
    build_attractors()
    #build_graph()
    startOSC()

'''
def update():
    # Main simulation loop.
    #graph.after(UPDATE_TIME, update)
    draw()
    move()
    makesound()
    global sim_time #necessary to prevent UnboundLocalError
    sim_time += 1 # iterate discreet time variable
    #if not (sim_time % 50): print "%d\n" % (sim_time) #keep track of time
    #if not (sim_time % 500): #randomly move attractors every once in a while
    #    for attractor in attractors:
    #        attractor.rand_update()

def draw():
    # Draw boids and attractors.
    # Shows only first 2 dimensions
    #graph.delete(ALL)
    for boid in boids:
        x1 = boid.position.x[0] - BOID_RADIUS
        y1 = boid.position.x[1] - BOID_RADIUS
        x2 = boid.position.x[0] + BOID_RADIUS
        y2 = boid.position.x[1] + BOID_RADIUS
        #graph.create_oval((x1, y1, x2, y2), fill='white')
        sendMsg('/boid', 1, pClient)
    for attractor in attractors:
        x1 = attractor.position.x[0] - ATTRACTOR_RADIUS
        y1 = attractor.position.x[1] - ATTRACTOR_RADIUS
        x2 = attractor.position.x[0] + ATTRACTOR_RADIUS
        y2 = attractor.position.x[1] + ATTRACTOR_RADIUS
        #graph.create_oval((x1, y1, x2, y2), fill='red')
        sendMsg('/boid', 2, pClient)
    #graph.update()
'''

def move():
    # Move all boids.
    for boid in boids:
        simulate_wall(boid)
        boid.update_velocity(boids)
        boid.move()

def makesound():
    global note_time
    global sim_time

    sim_time += 1 # iterate discreet time variable

    if not note_time:
        note_time = random.randint(10,100) #time of first note, in sim_time units
    ioi = 0 #note ioi is the last dimension
    #check to see if it's time to output a note
    if ((note_time < sim_time) & (MAXIOI<(500*0.95))):
        dimvals = [0.0]*NDIMS; #array for centroid values
        for i in range(NDIMS):
            dimvals[i] = 0
            for boid in boids:
                dimvals[i] += boid.position.x[i]
            dimvals[i] /= float( len(boids) * DIMLIMIT )  # normalize to range 0-1
            dimvals[i] = max(min(dimvals[i],1.0),0.0)     # make sure it's in range
        sendMsg('/swarmNote',dimvals,scClient)                     # send centroid values via osc
        ioi = dimvals[NDIMS-1] * float(MAXIOI - MINIOI) + float(MINIOI) #ioi is last dim
        note_time = sim_time + ioi                        # assign next note time

    for i in range(0, len(boids)):
        boid = boids[i]
        x = boid.position.x[0] - BOID_RADIUS
        y = boid.position.x[1] - BOID_RADIUS
        sendMsg('/boid', [i, float(x)/WIDTH, float(y)/HEIGHT], pClient)

    for i in range(0, len(attractors)):
        attractor = attractors[i]
        x = attractor.position.x[0] - ATTRACTOR_RADIUS
        y = attractor.position.x[1] - ATTRACTOR_RADIUS
        sendMsg('/attractor', [i, float(x)/WIDTH, float(y)/HEIGHT], pClient)


def simulate_wall(boid):
    # Create boundaries.
    for dim in range(NDIMS):
        if boid.position.x[dim] < WALL:
            boid.velocity.x[dim] += WALL_FORCE
        elif boid.position.x[dim] > WIDTH - WALL:
            boid.velocity.x[dim] -= WALL_FORCE

def limit_speed(boid):
    # Limit boid speed.
    for dim in range(NDIMS):
        if abs(boid.velocity.x[dim]) > SPEED_LIMIT:
            boid.velocity.x[dim] /= abs(boid.velocity.x[dim]) / SPEED_LIMIT

def build_boids():
    # Create boids variable.
    global boids
    boids = tuple(Boid([DIMLIMIT]*NDIMS, OFFSET_START, FRAMES_PER_SEC) for boid in xrange(BOIDS))

def build_attractors():
    # Create boids variable.
    global attractors
    attractors = tuple(Attractor(ATTRACTION) for attractor in xrange(ATTRACTORS))


################################################################################
# MULTIDIMENTIONAL SPACE
# Note: we implement dimensional decoupling. Makes more sense musically.

class MultiD:

    def __init__(self, x):
        self.x = [float(i) for i in x]

    def __repr__(self):
        return 'MultiD:\n'
        for dim in range(NDIMS):
            return '$s, ' % (self.x[dim])
        return '\n'

    def __add__(self, other):
        return MultiD((self.x[i] + other.x[i]) for i in range(NDIMS))

    def __sub__(self, other):
        return MultiD((self.x[i] - other.x[i]) for i in range(NDIMS))

    def __mul__(self, other):
        return MultiD((self.x[i] * other) for i in range(NDIMS))

    def __div__(self, other):
        return MultiD((self.x[i] / other) for i in range(NDIMS))

    def __iadd__(self, other):
        for dim in range(NDIMS):
            self.x[dim] += other.x[dim]
        return self

    def __isub__(self, other):
        for dim in range(NDIMS):
            self.x[dim] -= other.x[dim]
        return self

    def __idiv__(self, other):
        for dim in range(NDIMS):
            self.x[dim] /= other
        return self

################################################################################
# BOID RULE IMPLEMENTATION CLASS

class Boid:

    def __init__(self, lims, offset, move_divider):
        self.velocity = MultiD([0]*NDIMS)
        self.position = MultiD([0]*NDIMS)
        for dim in range(NDIMS):  #random starting position
            self.position.x[dim] = random.randint(0,DIMLIMIT)
        self.move_divider = move_divider * 5

    def update_velocity(self, boids):
        v1 = self.rule1(boids)
        v2 = self.rule2(boids)
        v4 = self.rule4(attractors)
        self.__temp = v1 + v2 + v4

    def move(self):
        self.velocity += self.__temp
        limit_speed(self)
        self.position += self.velocity / self.move_divider

    def rule1(self, boids):
        # clumping
        vector = MultiD([0]*NDIMS)
        for boid in boids:
            if boid is not self:
                vector += boid.position
        vector /= len(boids) - 1
        return (vector - self.position) / BOIDMASS

    def rule2(self, boids):
        # avoidance
        vector = MultiD([0]*NDIMS)
        for boid in boids:
            if boid is not self:
                for dim in range(NDIMS):
                    if abs(self.position.x[dim] - boid.position.x[dim]) < BLIMIT:
                        vector.x[dim] -= (boid.position.x[dim] - self.position.x[dim])
        return vector * 1.5

    #NOTE: NO rule3 BECAUSE WE DON'T IMPOSE VELOCITY MATCHING/SCHOOLING

    def rule4(self, attractors):
        # attractors
        vector = MultiD([0]*NDIMS)
        for attractor in attractors:
            for dim in range(NDIMS):
                if abs(self.position.x[dim] - attractor.position.x[dim]) < 30:
                  vector.x[dim] += (attractor.position.x[dim] - self.position.x[dim]) * attractor.attraction
        return vector

################################################################################
# ATTRACTOR CLASS

class Attractor:

    def __init__(self, attract):
        self.position = MultiD([0]*NDIMS)
        for dim in range(NDIMS):
            self.position.x[dim] = random.randint(1, DIMLIMIT)
        self.attraction = attract

    def rand_update(self):
        for dim in range(NDIMS):
            self.position.x[dim] = random.randint(1, DIMLIMIT)


################################################################################
# RECEIVING OSC

s = OSC.OSCServer(RECEIVE_ADDRESS)
s.addDefaultHandlers()

def attractor_handler(addr, tags, stuff, source):
    print "---"
    print "Received new osc msg from %s" % OSC.getUrlStr(source)
    print "With addr : %s" % addr
    print "Typetags %s" % tags
    global attractors
    attractor = random.choice(attractors) #modify a random attractor
    for item in stuff:
        print "data %f" % item
    # Assign dimension values
    for i in range(NDIMS):
        attractor.position.x[i] = int( min(max(stuff[i],0.0),1.0) * DIMLIMIT )
    print "Dim %d val: %d" % (i,attractor.position.x[i])
    print "---"
s.addMsgHandler("/attr", attractor_handler) # adding our function

#set only one dimension value for an attractor
# send this msg: /attr_dim num val
#                where num is the dimension value and val is between 0 and 1
def attr_dim_handler(addr, tags, stuff, source):
    print "---"
    print "Received new osc msg from %s" % OSC.getUrlStr(source)
    print "With addr : %s" % addr
    print "Typetags %s" % tags
    global attractors
    attractor = random.choice(attractors) #modify a random attractor
    for item in stuff:
        print "data %f" % item
    # Assign dimension value
    attractor.position.x[stuff[0]] = int( min(max(stuff[1],0.0),1.0) * DIMLIMIT )
    print "Dim %d val: %d" % (stuff[0],attractor.position.x[stuff[1]])
    print "---"
s.addMsgHandler("/attr_dim", attr_dim_handler) # adding our function

# reset boid positions to random values
def reset_boids_handler(addr, tags, stuff, source):
    print "---"
    print "Received new osc msg from %s" % OSC.getUrlStr(source)
    print "With addr : %s" % addr
    print "Typetags %s" % tags
    global boids
    for boid in boids:
        for dim in range(NDIMS):
            boid.position.x[dim] = random.randint(1, DIMLIMIT)
    print "---"
s.addMsgHandler("/resetboids", reset_boids_handler)

def ioi_handler(addr, tags, stuff, source):
    print "---"
    print "Received new osc msg from %s" % OSC.getUrlStr(source)
    print "With addr : %s" % addr
    print "Typetags %s" % tags
    global MAXIOI
    MAXIOI = int(stuff[0] * 500)
    print "---"
s.addMsgHandler("/ioi", ioi_handler)

#change speed limit
def speed_lim_handler(addr, tags, stuff, source):
    print "---"
    print "Received new osc msg from %s" % OSC.getUrlStr(source)
    print "With addr : %s" % addr
    print "Typetags %s" % tags
    global SPEED_LIMIT
    global UPPER_SPEED_LIMIT
    SPEED_LIMIT = stuff[0] * UPPER_SPEED_LIMIT    
    print "Speed Limit: %f" % (SPEED_LIMIT)
    print "---"
s.addMsgHandler("/speed", speed_lim_handler) # adding our function

def startOSC(): # Start OSCServer
  print "\nStarting OSCServer.\n"
  global st
  st = threading.Thread( target = s.serve_forever )
  st.start()

def quit_handler(): # close OSC server
  print "Closing OSCServer."
  s.close()
  print "Waiting for Server-thread to finish."
  st.join() ##!!!
  print "Done."
  #graph.quit()

################################################################################
# SENDING OSC

def sendMsg(addr, val, client):
    msg = OSC.OSCMessage() #  we reuse the same variable msg used above overwriting it
    msg.setAddress(addr)   # something like "/note"
    msg.append(val)        # the corresponding value
#    if client is scClient:
#        print client
#        print addr
#        print val
    client.send(msg)       # now we dont need to tell the client the address anymore

################################################################################

# Execute the simulation.
if __name__ == '__main__':
    main()
