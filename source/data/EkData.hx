package data;

import utils.ClientPrefs;

class EKData {
    public static var keysShit:Map<Int, Map<String, Dynamic>> = [ // Ammount of keys = num + 1
		0 => [
            "letters" => ["E"], 
            "anims" => ["UP"], 
            "strumAnims" => ["SPACE"], 
            "pixelAnimIndex" => [4], 
            "sustaincolor" => ['cccccc']
        ],
		1 => [
            "letters" => ["A", "D"],
            "anims" => ["LEFT", "RIGHT"], 
            "strumAnims" => ["LEFT", "RIGHT"], 
            "pixelAnimIndex" => [0, 3], 
            "sustaincolor" => ['c24b99', 'f9393f']
        ],
		2 => [
            "letters" => ["A", "E", "D"], 
            "anims" => ["LEFT", "UP", "RIGHT"], 
            "strumAnims" => ["LEFT", "SPACE", "RIGHT"], 
            "pixelAnimIndex" => [0, 4, 3], 
            "sustaincolor" => ['c24b99', 'cccccc', 'f9393f']
        ],
		3 => [
            "letters" => ["A", "B", "C", "D"], 
            "anims" => ["LEFT", "DOWN", "UP", "RIGHT"], 
            "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT"], 
            "pixelAnimIndex" => [0, 1, 2, 3], 
            "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f']
        ],
		4 => [
            "letters" => ["A", "B", "E", "C", "D"], 
            "anims" => ["LEFT", "DOWN", "UP", "UP", "RIGHT"],
			"strumAnims" => ["LEFT", "DOWN", "SPACE", "UP", "RIGHT"],
            "pixelAnimIndex" => [0, 1, 4, 2, 3],
            "sustaincolor" => ['c24b99', '00ffff', 'cccccc' ,'12fa05', 'f9393f']
        ],
		5 => [
            "letters" => ["A", "C", "D", "F", "B", "I"], 
            "anims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"],
			"strumAnims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"], 
            "pixelAnimIndex" => [0, 2, 3, 5, 1, 8], 
            "sustaincolor" => ['c24b99', '12fa05', 'f9393f', 'ffff00', '00ffff', '0033ff']
        ],
		6 => [
            "letters" => ["A", "C", "D", "E", "F", "B", "I"],
            "anims" => ["LEFT", "UP", "RIGHT", "UP", "LEFT", "DOWN", "RIGHT"],
			"strumAnims" => ["LEFT", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "RIGHT"], 
            "pixelAnimIndex" => [0, 2, 3, 4, 5, 1, 8],
            "sustaincolor" => ['c24b99', '12fa05', 'f9393f', 'cccccc', 'ffff00', '00ffff', '0033ff']
        ],
		7 => [
            "letters" => ["A", "B", "C", "D", "F", "G", "H", "I"], 
            "anims" => ["LEFT", "UP", "DOWN", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
			"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
            "pixelAnimIndex" => [0, 1, 2, 3, 5, 6, 7, 8],
            "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f', 'ffff00', '8b4aff', 'ff0000', '0033ff']
        ],
		8 => [
            "letters" => ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
            "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
			"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT"], 
            "pixelAnimIndex" => [0, 1, 2, 3, 4, 5, 6, 7, 8],
            "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f', 'cccccc', 'ffff00', '8b4aff', 'ff0000', '0033ff']
        ],
		9 => [
            "letters" => ["A", "B", "C", "D", "E", "J", "F", "G", "H", "I"],
            "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "UP", "UP", "LEFT", "DOWN", "UP", "RIGHT"],
			"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "CIRCLE", "LEFT", "DOWN", "UP", "RIGHT"],
            "pixelAnimIndex" => [0, 1, 2, 3, 4, 9, 5, 6, 7, 8],
            "sustaincolor" => ['c24b99', '00ffff', '12fa05', 'f9393f', 'cccccc', 'cccccc', 'ffff00', '8b4aff', 'ff0000', '0033ff']
        ],
	];
}

class Keybinds
{
    public static function optionShit():Array<Dynamic> {
        return [
            ['1 KEY'],
            ['Center', 'note_one1'],
            [''],
            ['2 KEYS'],
            ['Left', 'note_two1'],
            ['Right', 'note_two2'],
            [''],
            ['3 KEYS'],
            ['Left', 'note_three1'],
            ['Center', 'note_three2'],
            ['Right', 'note_three3'],
            [''],
            ['4 KEYS'],
            ['Left', 'note_left'],
            ['Down', 'note_down'],
            ['Up', 'note_up'],
            ['Right', 'note_right'],
            [''],
            ['5 KEYS'],
            ['Left', 'note_five1'],
            ['Down', 'note_five2'],
            ['Center', 'note_five3'],
            ['Up', 'note_five4'],
            ['Right', 'note_five5'],
            [''],
            ['6 KEYS'],
            ['Left 1', 'note_six1'],
            ['Up', 'note_six2'],
            ['Right 1', 'note_six3'],
            ['Left 2', 'note_six4'],
            ['Down', 'note_six5'],
            ['Right 2', 'note_six6'],
            [''],
            ['7 KEYS'],
            ['Left 1', 'note_seven1'],
            ['Up', 'note_seven2'],
            ['Right 1', 'note_seven3'],
            ['Center', 'note_seven4'],
            ['Left 2', 'note_seven5'],
            ['Down', 'note_seven6'],
            ['Right 2', 'note_seven7'],
            [''],
            ['8 KEYS'],
            ['Left 1', 'note_eight1'],
            ['Down 1', 'note_eight2'],
            ['Up 1', 'note_eight3'],
            ['Right 1', 'note_eight4'],
            ['Left 2', 'note_eight5'],
            ['Down 2', 'note_eight6'],
            ['Up 2', 'note_eight7'],
            ['Right 2', 'note_eight8'],
            [''],
            ['9 KEYS'],
            ['Left 1', 'note_nine1'],
            ['Down 1', 'note_nine2'],
            ['Up 1', 'note_nine3'],
            ['Right 1', 'note_nine4'],
            ['Center', 'note_nine5'],
            ['Left 2', 'note_nine6'],
            ['Down 2', 'note_nine7'],
            ['Up 2', 'note_nine8'],
            ['Right 2', 'note_nine9'],
            [''],
            ['10 KEYS'],
            ['Left 1', 'note_ten1'],
            ['Down 1', 'note_ten2'],
            ['Up 1', 'note_ten3'],
            ['Right 1', 'note_ten4'],
            ['Center 1', 'note_ten5'],
            ['Center 2', 'note_ten6'],
            ['Left 2', 'note_ten7'],
            ['Down 2', 'note_ten8'],
            ['Up 2', 'note_ten9'],
            ['Right 2', 'note_ten10'],
            [''],
            ['UI'],
            ['Left', 'ui_left'],
            ['Down', 'ui_down'],
            ['Up', 'ui_up'],
            ['Right', 'ui_right'],
            [''],
            ['Reset', 'reset'],
            ['Accept', 'accept'],
            ['Back', 'back'],
            ['Pause', 'pause'],
            [''],
            ['VOLUME'],
            ['Mute', 'volume_mute'],
            ['Up', 'volume_up'],
            ['Down', 'volume_down'],
            [''],
            ['DEBUG'],
            ['Key 1', 'debug_1'],
            ['Key 2', 'debug_2']
        ];
    }

    public static function fill():Array<Array<Dynamic>>
    {
        return [
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_one1'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_two1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_two2'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three3'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five5'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six6'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven7'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight8'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine9'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten9')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_ten10'))
			]
		];
    }
}