using System;
using System.Collections.Generic;
using System.Reflection;
using BepInEx;
using HarmonyLib;
using UnityEngine;

namespace MyMod
{
    [BepInPlugin("com.mymod.id", "My Mod v2", "1.0.0")]
    public class PluginV2 : BaseUnityPlugin
    {
        private void Awake()
        {
            Logger.LogInfo("Mod v2 loading...");
            var harmony = new Harmony("com.mymod.id");
            harmony.PatchAll();
            Logger.LogInfo("Mod loaded! Multiplier: 3x");
        }
    }

    [HarmonyPatch]
    public static class MyPatches
    {
        private static float _mult = 3f;

        // Example: Hook a method that returns int
        [HarmonyPatch(typeof(GameManager_New), "TargetMethodName")]
        [HarmonyPostfix]
        public static void TargetMethodName_Postfix(ref int __result)
        {
            int orig = __result;
            __result = Mathf.RoundToInt(__result * _mult);
            if (orig != __result)
                Debug.Log("[Mod] Value " + orig + " -> " + __result);
        }

        // Example: Hook a method that takes int args
        [HarmonyPatch(typeof(GameManager_New), "AnotherMethod")]
        [HarmonyPrefix]
        public static void AnotherMethod_Prefix(ref object[] __args)
        {
            for (int i = 0; i < __args.Length; i++)
            {
                if (__args[i] is int)
                {
                    int val = (int)__args[i];
                    if (val > 0 && val < 1000)
                    {
                        __args[i] = Mathf.RoundToInt(val * _mult);
                        Debug.Log("[Mod] Arg " + val + " -> " + __args[i]);
                    }
                }
            }
        }
    }
}
