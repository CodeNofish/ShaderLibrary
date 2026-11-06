using UnityEngine;
using UnityEngine.UI;

namespace ShaderLibrary.UI {

  public class BlurUI : BaseUI, IMaterialModifier {
    private float _blur;

    public float Blur {
      get => _blur;
      set {
        _blur = value;
        Graphic.SetMaterialDirty();
      }
    }

    protected override void Awake() {
      base.Awake();
      
    }

    public Material GetModifiedMaterial(Material baseMaterial) {
      if (!Application.isPlaying || enabled == false)
        return baseMaterial;
      
      return baseMaterial;
    }
  }

}
