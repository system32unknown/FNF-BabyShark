package ui.framerate;

import openfl.text.TextField;

class EngineField extends TextField {
    public function new() {
        super();
        defaultTextFormat = Overlay.textFormat;
        autoSize = LEFT;
        multiline = wordWrap = false;
        text = 'PSYCH 0.6.3 / ALTER 0.1';
    }
}