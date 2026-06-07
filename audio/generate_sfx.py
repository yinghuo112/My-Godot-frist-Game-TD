import wave, struct, math, random, os

RATE = 22050

def write_wav(path, samples):
    data = b""
    for s in samples:
        s = max(-32768, min(32767, int(s * 32767)))
        data += struct.pack("<h", s)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)

def tone(freq, dur, amp, descend=False):
    n = int(RATE*dur); o=[]
    for i in range(n):
        t=i/RATE; f=freq*(1-t/dur*0.5) if descend else freq
        o.append(math.sin(2*math.pi*f*t)*amp*(1-i/n))
    return o

def sweep(f1,f2,dur,amp):
    n=int(RATE*dur); o=[]
    for i in range(n):
        t=i/RATE; f=f1+(f2-f1)*t/dur
        o.append(math.sin(2*math.pi*f*t)*amp*(1-t/dur))
    return o

def lightning():
    n=int(RATE*0.15); o=[]
    for i in range(n):
        t=i/RATE
        o.append((random.uniform(-1,1)*0.7+math.sin(2*math.pi*3000*t)*0.3)*(1-i/n)*0.5)
    return o

def noise_tone(freq,dur,amp):
    n=int(RATE*dur); o=[]
    for i in range(n):
        t=i/RATE
        o.append((random.uniform(-1,1)*0.5+math.sin(2*math.pi*freq*t)*0.5)*(1-i/n)*amp)
    return o

set1 = {
    "shoot": tone(800,0.08,0.4),
    "die": tone(200,0.12,0.3,True),
    "wave": sweep(300,700,0.4,0.3),
    "gameover": sweep(500,100,0.6,0.4),
    "lightning": lightning(),
    "fireball": noise_tone(100,0.25,0.5),
    "freeze": noise_tone(4000,0.2,0.3),
    "upgrade": sweep(400,1200,0.3,0.4),
    "coin": tone(1800,0.08,0.3),
    "ui_click": tone(1000,0.03,0.2),
    "place": tone(120,0.1,0.5),
    "sell": sweep(600,200,0.15,0.35),
}

def sq(t,f): return 1.0 if math.sin(2*math.pi*f*t)>=0 else -1.0
def saw(t,f): return 2.0*(f*t-math.floor(f*t+0.5))
def tri(t,f):
    p=(f*t)%1.0
    return 2.0*abs(2.0*p-1.0)-1.0
def vib_f(t,base,depth=0.05,speed=8):
    return base*(1+depth*math.sin(2*math.pi*speed*t))

def adsr(i,n,a=0.1,d=0.2,s=0.5,r=0.8):
    aa=int(n*a);dd=int(n*d);rr=int(n*r)
    if i<aa: return i/aa
    if i<dd: return 1-(1-s)*(i-aa)/(dd-aa)
    if i<rr: return s
    return s*(1-(i-rr)/(n-rr))

def gen_set2():
    sfx={}
    # shoot
    n=int(RATE*0.08);o=[]
    for i in range(n):
        t=i/RATE;o.append((sq(t,1200)*0.3+random.uniform(-1,1)*0.2)*(1-t/0.08)*0.6)
    sfx["shoot"]=o
    # die
    n=int(RATE*0.2);o=[]
    for i in range(n):
        t=i/RATE;f=150*(1-t/0.2*0.6)
        o.append((saw(t,f)*0.3+random.uniform(-1,1)*0.15)*(1-t/0.2)*0.5)
    sfx["die"]=o
    # wave
    n=int(RATE*0.5);o=[]
    for i in range(n):
        t=i/RATE;f=200+600*t/0.5
        o.append((sq(t,f)*0.25+saw(t,f)*0.15)*adsr(i,n,0.05,0.1,0.7,0.85)*0.5)
    sfx["wave"]=o
    # gameover
    n=int(RATE*0.8);o=[]
    for i in range(n):
        t=i/RATE;f=500-450*t/0.8
        o.append(sq(t,f)*0.3*(1-t/0.8)*0.4)
    sfx["gameover"]=o
    # lightning
    n=int(RATE*0.2);o=[]
    for i in range(n):
        t=i/RATE
        o.append((random.uniform(-1,1)*1.2+sq(t,3500)*0.3)*(1-t/0.2)*0.5)
    sfx["lightning"]=o
    # fireball
    n=int(RATE*0.3);o=[]
    for i in range(n):
        t=i/RATE;f=80+120*t/0.3
        o.append((saw(t,f)*0.3+random.uniform(-1,1)*0.5)*adsr(i,n,0.05,0.15,0.6,0.8)*0.5)
    sfx["fireball"]=o
    # freeze
    n=int(RATE*0.25);o=[]
    for i in range(n):
        t=i/RATE;v=1+0.3*math.sin(2*math.pi*20*t)
        o.append((math.sin(2*math.pi*4000*v*t)*0.3+random.uniform(-1,1)*0.2)*adsr(i,n,0.02,0.1,0.5,0.7)*0.4)
    sfx["freeze"]=o
    # upgrade
    st=[400,600,900,1200];n=int(RATE*0.35);o=[]
    for i in range(n):
        t=i/RATE;f=st[min(int(t/0.35*4),3)]
        o.append((math.sin(2*math.pi*f*t)*0.3+sq(t,f)*0.15)*adsr(i,n,0.02,0.05,0.8,0.9)*0.5)
    sfx["upgrade"]=o
    # coin
    n=int(RATE*0.12);o=[]
    for i in range(n):
        t=i/RATE;f=2500 if t<0.06 else 3000
        o.append(math.sin(2*math.pi*f*t)*0.3*(1-t/0.12)*0.5)
    sfx["coin"]=o
    # ui_click
    n=int(RATE*0.04);o=[]
    for i in range(n):
        t=i/RATE
        o.append((random.uniform(-1,1)*0.6+sq(t,2000)*0.2)*(1-t/0.04)*0.4)
    sfx["ui_click"]=o
    # place
    n=int(RATE*0.12);o=[]
    for i in range(n):
        t=i/RATE;f=100*(1-t/0.12*0.3)
        o.append((sq(t,f)*0.3+random.uniform(-1,1)*0.2)*adsr(i,n,0.01,0.03,0.6,0.7)*0.5)
    sfx["place"]=o
    # sell
    n=int(RATE*0.2);o=[]
    for i in range(n):
        t=i/RATE;f=800-700*t/0.2
        o.append((saw(t,f)*0.3+random.uniform(-1,1)*0.15)*(1-t/0.2)*0.4)
    sfx["sell"]=o
    return sfx

set2 = gen_set2()

def gen_set3():
    sfx={}
    # shoot: 800Hz三角波+下行颤音, 短促
    n=int(RATE*0.08);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,800,0.08,20)*(1-t/0.08*0.25)
        o.append(tri(t,f)*0.4*(1-t/0.08))
    sfx["shoot"]=o
    # die: 200Hz下行三角波+慢颤音
    n=int(RATE*0.2);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,200*(1-t/0.2*0.6),0.04,6)
        o.append(tri(t,f)*0.35*(1-t/0.2))
    sfx["die"]=o
    # wave: 300→700Hz sweep+柔和颤音
    n=int(RATE*0.5);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,300+400*t/0.5,0.03,5)
        o.append(tri(t,f)*0.3*(1-t/0.5))
    sfx["wave"]=o
    # gameover: 500→100Hz sweep+重颤音
    n=int(RATE*0.8);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,500-400*t/0.8,0.08,4)
        o.append(tri(t,f)*0.35*(1-t/0.8))
    sfx["gameover"]=o
    # lightning: 噪声+3000Hz三角波+混乱颤音
    n=int(RATE*0.2);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,3000,0.15,30)
        o.append((random.uniform(-1,1)*0.7+tri(t,f)*0.3)*(1-t/0.2)*0.5)
    sfx["lightning"]=o
    # fireball: 80→200Hz低频三角波+噪声
    n=int(RATE*0.3);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,80+120*t/0.3,0.02,10)
        o.append((tri(t,f)*0.4+random.uniform(-1,1)*0.3)*(1-t/0.3)*0.5)
    sfx["fireball"]=o
    # freeze: 4000Hz三角波+快速颤音
    n=int(RATE*0.25);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,4000,0.06,25)
        o.append((tri(t,f)*0.5+random.uniform(-1,1)*0.15)*adsr(i,n,0.02,0.1,0.5,0.7)*0.4)
    sfx["freeze"]=o
    # upgrade: 四音阶琶音400/600/900/1200+颤音
    st=[400,600,900,1200];n=int(RATE*0.35);o=[]
    for i in range(n):
        t=i/RATE;base=st[min(int(t/0.35*4),3)];f=vib_f(t,base,0.03,10)
        o.append((tri(t,f)*0.4+math.sin(2*math.pi*f*t)*0.15)*adsr(i,n,0.02,0.05,0.8,0.9)*0.5)
    sfx["upgrade"]=o
    # coin: 两段三角波2500→3000Hz+颤音
    n=int(RATE*0.12);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,2500 if t<0.06 else 3000,0.04,15)
        o.append(tri(t,f)*0.35*(1-t/0.12)*0.5)
    sfx["coin"]=o
    # ui_click: 1000Hz极短三角脉冲
    n=int(RATE*0.04);o=[]
    for i in range(n):
        t=i/RATE;o.append(tri(t,1000)*0.3*(1-t/0.04))
    sfx["ui_click"]=o
    # place: 120Hz低频三角重击+微颤音
    n=int(RATE*0.12);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,120*(1-t/0.12*0.3),0.02,8)
        o.append((tri(t,f)*0.4+random.uniform(-1,1)*0.15)*adsr(i,n,0.01,0.03,0.6,0.7)*0.5)
    sfx["place"]=o
    # sell: 600→200Hz下行sweep+颤音
    n=int(RATE*0.2);o=[]
    for i in range(n):
        t=i/RATE;f=vib_f(t,600-400*t/0.2,0.05,8)
        o.append(tri(t,f)*0.35*(1-t/0.2))
    sfx["sell"]=o
    return sfx

set3 = gen_set3()

base = r"D:\Administrator\Game\first-游戏\audio"
for name, samples in set1.items():
    path = os.path.join(base, "1", f"sfx_{name}.wav")
    write_wav(path, samples)
    print(f"1/{name}  ({len(samples)} samples)")
for name, samples in set2.items():
    path = os.path.join(base, "2", f"sfx_{name}.wav")
    write_wav(path, samples)
    print(f"2/{name}  ({len(samples)} samples)")
os.makedirs(os.path.join(base, "3"), exist_ok=True)
for name, samples in set3.items():
    path = os.path.join(base, "3", f"sfx_{name}.wav")
    write_wav(path, samples)
    print(f"3/{name}  ({len(samples)} samples)")
print("Done.")
