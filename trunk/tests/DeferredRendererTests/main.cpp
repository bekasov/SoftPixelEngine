//
// SoftPixel Engine - DeferredRenderer Tests
//

#include <SoftPixelEngine.hpp>
#include <RenderSystem/DeferredRenderer/spShadowMapper.hpp>

using namespace sp;

#ifdef SP_COMPILE_WITH_DEFERREDRENDERER

#include "../common.hpp"

SP_TESTS_DECLARE

video::Texture* DiffuseMap  = 0;
video::Texture* NormalMap   = 0;
video::Texture* HeightMap   = 0;

static void SetupShading(scene::Mesh* Obj, bool AutoMap = false, f32 Density = 0.7f)
{
    if (Obj)
    {
        if (AutoMap)
            Obj->textureAutoMap(0, Density);
        
        Obj->addTexture(DiffuseMap);
        Obj->addTexture(NormalMap);
        Obj->addTexture(HeightMap);
        
        Obj->updateTangentSpace(1, 2, false);
        
        Obj->getMaterial()->setBlending(false);
        //Obj->setShaderClass(DefRenderer->getGBufferShader());
    }
}

static scene::Mesh* CreateBox(const dim::vector3df &Pos, f32 RotationY)
{
    scene::Mesh* Obj = spScene->createMesh(scene::MESH_CUBE);
    
    Obj->setPosition(Pos);
    Obj->setRotation(dim::vector3df(0, RotationY, 0));
    
    SetupShading(Obj, true);
    
    return Obj;
}

int main()
{
    SP_TESTS_INIT_EX2(
        video::RENDERER_OPENGL,
        dim::size2di(1024, 768),
        //video::VideoModeEnumerator().getDesktop().Resolution,
        //VideoModes.getDesktop().Resolution,
        "DeferredRenderer",
        false,
        SDeviceFlags()
    )
    
    //spRenderer->setVsync(false);
    
    // Create deferred renderer
    video::DeferredRenderer* DefRenderer = new video::DeferredRenderer();
    
    DefRenderer->generateResources(
        video::DEFERREDFLAG_NORMAL_MAPPING
        | video::DEFERREDFLAG_PARALLAX_MAPPING
        //| video::DEFERREDFLAG_BLOOM
        | video::DEFERREDFLAG_SHADOW_MAPPING
        
        #if 0
        | video::DEFERREDFLAG_DEBUG_GBUFFER
        | video::DEFERREDFLAG_DEBUG_GBUFFER_WORLDPOS
        | video::DEFERREDFLAG_DEBUG_GBUFFER_TEXCOORDS
        #endif
    );
    
    //DefRenderer->setAmbientColor(0.0f);
    
    // Load textures
    const io::stringc Path = "../../help/tutorials/ShaderLibrary/media/";
    
    spRenderer->setTextureGenFlags(video::TEXGEN_MIPMAPFILTER, video::FILTER_ANISOTROPIC);
    spRenderer->setTextureGenFlags(video::TEXGEN_ANISOTROPY, 8);
    
    DiffuseMap  = spRenderer->loadTexture(Path + "StoneColorMap.jpg");
    NormalMap   = spRenderer->loadTexture(Path + "StoneNormalMap.jpg");
    HeightMap   = spRenderer->loadTexture("StonesHeightMap.jpg");
    
    // Create scene
    Cam->setPosition(dim::vector3df(0, 0, -1.5f));
    
    scene::SceneManager::setDefaultVertexFormat(DefRenderer->getVertexFormat());
    
    #define SCENE_WORLD
    #ifdef SCENE_WORLD
    
    scene::Mesh* Obj = spScene->loadMesh("TestScene.spm");
    Obj->setScale(2);
    
    #else
    
    scene::Mesh* Obj = spScene->createMesh(scene::MESH_CUBE);
    
    #endif
    
    SetupShading(Obj, true, 0.35f);
    
    f32 Rot = 0.0f;
    for (s32 i = -5; i <= 5; ++i)
    {
        CreateBox(dim::vector3df(1.5f*i, -1.5f, 0), Rot);
        Rot += 9.0f;
    }
    
    // Setup lighting
    scene::Light* Lit = spScene->getLightList().front();
    
    Lit->setLightModel(scene::LIGHT_POINT);
    Lit->setPosition(dim::vector3df(3.0f, 1.0f, 0.0f));
    Lit->setVolumetric(true);
    Lit->setVolumetricRadius(50.0f);
    
    scene::Light* SpotLit = spScene->createLight(scene::LIGHT_SPOT);
    SpotLit->setSpotCone(15.0f, 30.0f);
    SpotLit->setDiffuseColor(video::color(255, 32, 32));
    SpotLit->setPosition(dim::vector3df(-3, 0, 0));
    SpotLit->setShadow(true);
    
    // Create font
    video::Font* Fnt = spRenderer->createFont("Arial", 15);
    
    io::Timer timer(true);
    
    // Main loop
    while (spDevice->updateEvents() && !spControl->keyDown(io::KEY_ESCAPE))
    {
        spRenderer->clearBuffers();
        
        // Update scene
        if (spControl->keyDown(io::KEY_PAGEUP))
            SpotLit->turn(dim::vector3df(0, 1, 0));
        if (spControl->keyDown(io::KEY_PAGEDOWN))
            SpotLit->turn(dim::vector3df(0, -1, 0));
        
        if (spControl->keyDown(io::KEY_INSERT))
            SpotLit->turn(dim::vector3df(1, 0, 0));
        if (spControl->keyDown(io::KEY_DELETE))
            SpotLit->turn(dim::vector3df(-1, 0, 0));
        
        #ifdef SCENE_WORLD
        if (spContext->isWindowActive())
            tool::Toolset::moveCameraFree(0, spControl->keyDown(io::KEY_SHIFT) ? 0.25f : 0.125f);
        #else
        //tool::Toolset::presentModel(Obj);
        #endif
        
        #if 1
        s32 w = spControl->getMouseWheel();
        if (w)
        {
            static f32 g = 0.6f;
            g += static_cast<f32>(w) * 0.1f;
            DefRenderer->changeBloomFactor(g);
        }
        #endif
        
        // Render scene
        #if 1
        DefRenderer->renderScene(spScene, Cam);
        #else
        spScene->renderScene();
        #endif
        
        #if 0
        spRenderer->beginDrawing2D();
        spRenderer->draw2DText(Fnt, 15, "FPS: " + io::stringc(timer.getFPS()));
        spRenderer->endDrawing2D();
        #endif
        
        spContext->flipBuffers();
    }
    
    delete DefRenderer;
    
    deleteDevice();
    
    return 0;
}

#else

int main()
{
    io::Log::error("This engine was not compiled with deferred renderer");
    io::Log::pauseConsole();
    return 0;
}

#endif
