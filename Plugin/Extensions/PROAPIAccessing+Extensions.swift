extension PROAPIAccessing {
    var parameterCreationAPI: FxParameterCreationAPI_v5 {
        api(for: FxParameterCreationAPI_v5.self) as! FxParameterCreationAPI_v5
    }

    var parameterRetrievalAPI: FxParameterRetrievalAPI_v6 {
        api(for: FxParameterRetrievalAPI_v6.self) as! FxParameterRetrievalAPI_v6
    }

    var parameterSettingAPI: FxParameterSettingAPI_v6 {
        api(for: FxParameterSettingAPI_v6.self) as! FxParameterSettingAPI_v6
    }

    var timingAPI: FxTimingAPI_v4 {
        api(for: FxTimingAPI_v4.self) as! FxTimingAPI_v4
    }
}
