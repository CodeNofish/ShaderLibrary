using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ShaderLibrary.UI {

  [RequireComponent(typeof(Graphic))]
  public class BaseUI : UIBehaviour {
    private Graphic? _graphic;

    public Graphic Graphic {
      get {
        if (_graphic == null)
          _graphic = GetComponent<Graphic>();
        return _graphic;
      }
    }
  }

}
