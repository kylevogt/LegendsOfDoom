final int screenWidth = 512;
final int screenHeight = 432;
final int levelWidth = 1000;
final int levelHeight = 1000;
final int fieldMargin = 10;
final int frameRate = 30;

float DAMPENING = .75;
 
void initialize() {
	addScreen("level", new BasicLevel(levelWidth, levelHeight));  
}
 
void setup() {
	initialize();
	frameRate(frameRate);
}
 
class BasicLevel extends Level {
	BasicLevel(float levelWidth, float levelHeight) {
		super(levelWidth, levelHeight);
		addLevelLayer("layer", new BasicLayer(this));
		setViewBox(0,0,screenWidth,screenHeight);
	}

}
 
class BasicLayer extends LevelLayer {
	BasicPlayer player;
	Enemy enemy;

	BasicLayer(Level owner) {
		super(owner);

		addBoundary(new Boundary(0 + fieldMargin,height - fieldMargin, width - fieldMargin,height - fieldMargin)); //Bottom
	    addBoundary(new Boundary(width - fieldMargin,height - fieldMargin, width - fieldMargin,0 + fieldMargin)); //right
	    addBoundary(new Boundary(width  - fieldMargin,0 + fieldMargin,0 + fieldMargin,0 + fieldMargin)); //top
	    //addBoundary(new Boundary(0 + fieldMargin,0 + fieldMargin,width  - fieldMargin,0 + fieldMargin)); //top2
	    addBoundary(new Boundary(0 + fieldMargin,0 + fieldMargin,0 + fieldMargin,height - fieldMargin)); //left
		showBoundaries = true;

		player = new BasicPlayer(width/2,height/2);
		addPlayer(player);

		newEnemy();

		Sprite background = new Sprite("graphics/TileTest500x500.gif");
	    TilingSprite bgTile = new TilingSprite(background, 0,0,levelWidth,levelHeight);
	    addBackgroundSprite(bgTile);
	}

	void draw() {
		super.draw();
		viewbox.track(parent,player);
	}

	void newEnemy(){
		enemy = new Enemy();
		addInteractor(enemy);
	}

	void mouseClicked(int mx, int my, int button) {
		int offsetX = viewbox.getX();
		int offsetY = viewbox.getY();
		int x = mx+offsetX;
		int y = my+offsetY;
		player.shoot(x,y);
	}

	void mouseMoved(int mx, int my) {
	    int offsetX = viewbox.getX();
		int offsetY = viewbox.getY();
		int x = (mx+offsetX)-player.getX();
		int y = (my+offsetY)-player.getY();
		float angle = atan2(y, x);
		player.setRotation(angle);
	}
}

class BasicBullet extends Interactor{
	BasicBullet(int bx, int by,int mx, int my) { 
		super("BasicBullet"); 
		addState(new State("idle", "graphics/mario/small/Standing-mario.gif"));
		setCurrentState("idle");  
		startAcceleration(bx,by,mx,my);
		setPosition(bx,by);  
	}

	void startAcceleration(int bx, int by,int mx, int my){
		float x1=bx, y1=by, x2=mx, y2=my;
		float speed = 1;		
	    float angle = atan2(y1-y2, x1-x2);
	    if(angle<0) { angle += 2*PI; }
	    float ix = -cos(angle);
	    float iy = -sin(angle);
	    setAcceleration(speed*ix, speed*iy);
	}

	void gotBlocked(Boundary b, float[] intersection, float[] original) {
			layer.removeForInteractorsOnly(this);
  	}

  	// what happens when we touch another player or NPC?
    void overlapOccurredWith(Actor other, float[] direction) {
		if (other instanceof Enemy) {
			hitEnemy(other);
		}
    }

    void hitEnemy(Enemy enemy){
    	/* Can be overridden by child classes */
    	removeActor();
		enemy.removeActor();
		layer.newEnemy();
    };
	
}

class BasicGun{
	int lastShot = 0;
	int shootDelay = 200; //ms between shots
	LevelLayer layer;

	BasicGun(){
	}

	BasicGun(int shootDelay){
		this.shootDelay = shootDelay;
	}

	void setLevelLayer(LevelLayer layer) {
  		this.layer = layer;
	}

	void shoot(int playerX, int playerY,int targetX, int targetY) {
		float lastShotMS = float(lastShot/frameRate) * 1000;
		float currentMS = float(frameCount/frameRate) * 1000;
    	if( (currentMS - lastShotMS) >= shootDelay  ){
    		lastShot = frameCount;
    		BasicBullet bullet = new BasicBullet(playerX,playerY,targetX,targetY);
			layer.addForInteractorsOnly(bullet);
    	}	
	}
	

}

class BasicPlayer extends Player {

	BasicGun gun;

	BasicPlayer(float x, float y) {
		super("BasicPlayer");
		setupStates();
		setPosition(x,y);
		handleKey('W');
		handleKey('A');
		handleKey('S');
		handleKey('D');
		handleKey(' ');
		setImpulseCoefficients(DAMPENING,DAMPENING);
		gun = new BasicGun();
	}

  	void setLevelLayer(LevelLayer layer) {
  		this.layer = layer;
		gun.setLevelLayer(layer);
	}


	void setupStates() {
		addState(new State("idle", "graphics/testChar.png"));
		addState(new State("running", "graphics/Laura_Jones_Machine_Pistol.png",6,3));
		setCurrentState("idle");    
	}

	void shoot(targetX,targetY){
		gun.shoot(x,y,targetX,targetY);
	}

	void handleInput(){
		if (isKeyDown('W')) { 
			addImpulse(0,-2);
			setCurrentState("running");
		}
		if (isKeyDown('A')) { 
			addImpulse(-2,0);
			setCurrentState("running");
		}
		if (isKeyDown('S')) { 
			addImpulse(0,2);
			setCurrentState("running");
		}
		if (isKeyDown('D')) { 
			addImpulse(2,0);
			setCurrentState("running");
		}

		if (isKeyCodeDown(32)){
			int offsetX = layer.viewbox.getX();
			int offsetY = layer.viewbox.getY();
			int x = mouseX+offsetX;
			int y = mouseY+offsetY;
			shoot(x,y);
		}

		if(!isKeyDown('A') && !isKeyDown('D') && !isKeyDown('W') && !isKeyDown('S')) {
	      setCurrentState("idle");
	    }

	}
}

class Enemy extends Interactor implements Tracker {
	Enemy(){
		super("enemy");
		setStates();
	}

	void setStates(){
		addState(new State("idle","graphics/enemies/Boo-chasing.gif"));
	}

	void track(Actor actor, float x, float y, float w, float h) {
		GenericTracker.enemyTrack(this,actor,3);
	}

	// what happens when we touch another player or NPC?
    void overlapOccurredWith(Actor other, float[] direction) {
		if (other instanceof BasicPlayer) {
			//removeActor();
		}
    }
}