import std.stdio;

import Font = razor_font;

import Window = window.window;
import Camera = camera.camera;
import Shader = shader.shader;
import Texture = texture.texture;
import mesh.mesh;
import doml.vector_2d;

void main()
{
    // Window controls OpenGL and GLFW - general setup for opengl
    Window.initialize();
    Window.setTitle("BlockModel Editor");

    // 2d reference shader, you can take this and run with it
    Shader.create("2d", "shaders/2d_vertex.vs", "shaders/2d_fragment.fs");
    Shader.createUniform("2d", "cameraMatrix");
    Shader.createUniform("2d", "objectMatrix");
    Shader.createUniform("2d", "textureSampler");

    /**
    So here is the first example, you can pass through textures to your
    rendering engine as the file location (png) or as raw ubytes, it's
    totally up to you. This makes it so you can automatically add in 
    font textures into the shader/renderer/yada yada that you want to
    when you create a font!
    This example is very simple, just sending the Texture module the
    file location, fancy.
    */
    Font.setRenderTargetAPICallString(
        (string input){
            Texture.addTexture(input);
        }
    );


    /**
    A pretty neat example, this is just shoveling in a render
    function into RazorFont so that you can just do RazorFont.render()
    without worrying about anything else.

    You can also call this in your Mesh class, or whatever you want to do!

    This also flushes the cache. A double feature!
    */

    Font.setRenderFunc(
        (Font.RazorFontData fontData) {

            string fileLocation = Font.getCurrentFontTextureFileLocation();

            Mesh tempObject = new Mesh()
                .addVertices2d(fontData.vertexPositions)
                .addIndices(fontData.indices)
                .addTextureCoordinates(fontData.textureCoordinates)
                .setTexture(Texture.getTexture(fileLocation))
                .finalize();

            tempObject.render("2d");
            tempObject.cleanUp();
        }
    );

    /**
    Before we continue, I just wanted to let you know that I left 2 versions
    of both font PNGs in the example_fonts folder. One with the creation guides,
    the other without, I highly recommend you use creation guides to make or
    translate your font, then delete the guide lines. But you can do whatever
    you want! It's your font. :)

    So now we create some fonts like this:
    createFont(
        directory,
        optional name,
        optional horizontal trimming,
        character spacing (defaults to 1 pixel),
        space (' ') sizing (defaults to 4 pixels)
    )
    */

    // This one is my cool font
    Font.createFont("example_fonts/test_font", "cool", true);
    // You've never seen this font before
    Font.createFont("example_fonts/totally_original", "mc", true);

    // Hmm, I wonder why this variable is here? Maybe we'll find out later
    double rotation = 0.0;

    // A SECRET? Well okay then
    aSecret();

    // Into the main loop we gooooo
    while (!Window.shouldClose()) {

        // Just some regular ol opengl stuff
        Window.pollEvents();
        Camera.clearDepthBuffer();
        // We'll clear it as slightly off white
        Window.clear(0.9);

        // Now starts the reference shader!
        Shader.startProgram("2d");


        /**
        Now is a very important part, we must tell RazorFont how big our
        canvas is, without this, this whole thing isn't possible!
        */
        Font.setCanvasSize(Window.getWidth, Window.getHeight);

        // More GL things
        // The gui matrix is just a simple ortholinear matrix4x4 in case you're wondering
        Shader.setUniformMatrix4("2d", "cameraMatrix", Camera.updateGuiMatrix());
        Shader.setUniformMatrix4("2d", "objectMatrix", Camera.setGuiObjectMatrix(Vector2d(0,0)) );

        /**
        Now the fun begins, let's select the mc font
        */
        Font.selectFont("mc");

        /**
        That was pretty dang easy. So just remember, you have to either call
        render() or flush() before you can change fonts, as every font is different!

        So now we'll render it to the canavas. I want to render it to the top left.
        Let's go with the debug alphabet
        */
        Font.renderToCanvas(0,0, 32, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
        
        /**
        So that basically internally calculated the positions of the characters on
        screen for you! Very fancy. So now, let's do some more text!

        I scoped these so you can see each part happening in one fell swoop.
        */

        {
            int fontSize = 70;
            string textString = "I'm on the bottom right!";
            /**
            You can easily get the width and height of a section of text by doing
            this! It essentially does a "dry render" without setting anything internally.
            RazorTextSize is a struct that allows this to be truly generic, not
            interfering with your favorite math library!
            */
            Font.RazorTextSize textSize = Font.getTextSize(fontSize, textString);

            // Now we're going to move this to the bottom right of the "canvas"
            double posX = Window.getWidth - textSize.width;
            double posY = Window.getHeight - textSize.height;

            Font.renderToCanvas(posX, posY, fontSize, textString);
        }
        {
            int fontSize = 32;
            string textString = "The text below is rendered at the window center-point!";

            Font.RazorTextSize textSize = Font.getTextSize(fontSize, textString);

            // Now we're going to move slightly above the center point of the window
            double posX = (Window.getWidth / 2.0) - (textSize.width / 2.0);
            double posY = (Window.getHeight / 2.0) - (textSize.height / 2.0) - 50;

            Font.renderToCanvas(posX, posY, fontSize, textString);
        }

        /**
        That render function we set at the beginning of this tutorial?
        Yeah this is all we have to do to call it, anywhere, at any time.
        Well, as long as you have a render context :P

        This also runs flush() so we can now select a different font!
        */
        Font.render();

        // So let's select my magnum opus
        Font.selectFont("cool");

        /**
        And we'll do the fanciness explained above.

        But I want to explain something simple:
        
        So the top left of the text is the root position of it.
        So when you run this, I want you to observe that this text is
        rooted (top left) at the exact center of your window no matter what! 
        */
        string magnumOpusText = "this text is beautiful";
        Font.renderToCanvas(Window.getWidth / 2, Window.getHeight / 2, 54, magnumOpusText);

        /**
        Now one more thing, we're not going to use our fancy delegate function
        we supplied to RazorFont at the beginning of the program.
        
        Nahhhh. What if we want to be crazy and have each string be a new render call?

        I'm just kidding. This is useful for debugging!

        So now, I will show you how to extract the information straight from 
        RazorFont's cache without automating it. :)
        */

        Font.RazorFontData data = Font.flush();

        /**
        BAM! Now we have the vertex, texture, and indices data of "this text is beautiful"

        now, let's use it.
        */
        Mesh myCoolText2 = new Mesh()
            .addVertices2d(data.vertexPositions)
            .addIndices(data.indices)
            .addTextureCoordinates(data.textureCoordinates)
            .setTexture(Texture.getTexture("example_fonts/test_font.png"))
            .finalize();

        myCoolText2.render("2d");

        myCoolText2.cleanUp();


        /**
        Very fancy, very fancy.

        You could use this to create a MEGA buffer if you want!

        So the next thing is going to be something kinda cool. If your font
        is missing glyphs (characters) the library won't crash if it encounters them.
        It will simply skip them!

        I specifically made the test_font to miss ALL uppercase characters. You can see 
        this in the window. This is rendered on the bottom left of the window.
        */
        string uhOh = "thIs is mIsSiNg leTtErs";
        Font.RazorTextSize sizing = Font.getTextSize(34, uhOh);
        Font.renderToCanvas(0,Window.getHeight - sizing.height, 34, uhOh);
        Font.render();

        /**
        ths is msig letrs. A truer statement has never been spoken. Or rendered I guess.
        This is simply so if someone tries to type in different langs into your text, or maybe
        you were not feeling it, and are missing quite a few chars in your font, it will always 
        maintain safety.
        */


        /**
        So I wasn't going to do this part but I thought it would be neat to show you.

        There is also another reason to flush() text.
        
        Change this to true to see :)
        */

        if (false) {
            import doml.vector_3d;
            import delta_time;

            calculateDelta();

            rotation += getDelta() * 100;
            if (rotation > 360.0) {
                rotation -= 360.0;
            }

            Camera.clearDepthBuffer();

            Shader.startProgram("3d");

            Camera.setRotation(Vector3d(0,0,0));

            Shader.setUniformMatrix4("3d", "cameraMatrix", Camera.updateCameraMatrix());

            Shader.setUniformMatrix4("3d", "objectMatrix",
                Camera.setObjectMatrix(
                    Vector3d(0,0,-10),      // Translation
                    Vector3d(0,rotation,0), // Rotation
                    Vector3d(1,-1,1),       // Scale - Gotta flip that Y scale in 3d!
                )
            );

            Font.selectFont("mc");

            int fontSize = 1;
            string textString = "Stop the room from spinning, ahhhh!";

            Font.RazorTextSize textSize = Font.getTextSize(fontSize, textString);

            // Pure center :D
            double posX = (Window.getWidth / 2.0) - (textSize.width / 2.0);
            double posY = (Window.getHeight / 2.0) - (textSize.height / 2.0);
            Font.renderToCanvas(posX, posY, fontSize, textString);

            Font.RazorFontData myCoolData3d =  Font.flush();

            Mesh myCoolText3d = new Mesh()
                .addVertices2d(myCoolData3d.vertexPositions)
                .addIndices(myCoolData3d.indices)
                .addTextureCoordinates(myCoolData3d.textureCoordinates)
                // Oh wow I snuck in another feature woooo!
                .setTexture(Texture.getTexture(Font.getCurrentFontTextureFileLocation()))
                .finalize();

            myCoolText3d.render("3d");

            myCoolText3d.cleanUp();

            /**
            Why yes, this is another reason you can directly flush out the buffer :D
            */ 

        }

        // Update the gl window yada yada
        Window.swapBuffers();
    }

    // Just regular ol opengl cleanup
    Shader.deleteShader("2d");
    Shader.deleteShader("3d");
    Texture.cleanUp();
    Window.destroy();

}




























// Did you read the tutorial before you snooped down here? :D






























// You caught me, I hid a 3d shader in here to show you something cool :P
void aSecret() {
    Shader.create("3d", "libs/regular_vertex.vs", "libs/regular_fragment.fs");
    Shader.createUniform("3d", "cameraMatrix");
    Shader.createUniform("3d", "objectMatrix");
    Shader.createUniform("3d", "textureSampler");
}