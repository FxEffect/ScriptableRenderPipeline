using UnityEditor.Graphing;
using UnityEngine;

#if UNITY_2019_1_OR_NEWER
using UnityEditor.UIElements;
using UnityEngine.UIElements;
#else
using UnityEditor.Experimental.UIElements;
using UnityEngine.Experimental.UIElements;
#endif

namespace UnityEditor.ShaderGraph.Drawing.Slots
{
    public class ColorRGBASlotControlView : VisualElement
    {
        ColorRGBAMaterialSlot m_Slot;

        public ColorRGBASlotControlView(ColorRGBAMaterialSlot slot)
        {
            AddStyleSheetPath("Styles/Controls/ColorRGBASlotControlView");
            m_Slot = slot;
            var colorField = new ColorField { value = slot.value, showEyeDropper = false };
            colorField.OnValueChanged(OnValueChanged);
            Add(colorField);
        }

        void OnValueChanged(ChangeEvent<Color> evt)
        {
            m_Slot.owner.owner.owner.RegisterCompleteObjectUndo("Color Change");
            m_Slot.value = evt.newValue;
            m_Slot.owner.Dirty(ModificationScope.Node);
        }
    }
}
