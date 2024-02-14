package states.stages;

class House extends BaseStage {
    override function create() {
		add(new BGSprite('house/sky', -600, -300, .6, .6));
        add(new BGSprite('house/hills', -834, -159, .7, .7));
        add(new BGSprite('house/grass bg', -1205, 580));
        add(new BGSprite('house/gate', -755, 250));
        add(new BGSprite('house/grass', -832, 505));
    }
}