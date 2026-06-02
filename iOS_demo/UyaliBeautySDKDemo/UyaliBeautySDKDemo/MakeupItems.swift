//
//  MakeupItems.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/3/20.
//

import Foundation
import UyaliBeautySDK

//眉毛
public let eyebrowString = [
    "eyebrow_biaozhun",
    "eyebrow_cupin",
    "eyebrow_juanyan",
    "eyebrow_liuxing",
    "eyebrow_liuye",
    "eyebrow_qiubo",
    "eyebrow_wanyue",
    "eyebrow_xinyue",
    "eyebrow_yesheng",
    "eyebrow_yuanshan"
]

public let eyebrowType: [MakeupEyebrowType] = [
    .eyebrow_biaozhun,
    .eyebrow_cupin,
    .eyebrow_juanyan,
    .eyebrow_liuxing,
    .eyebrow_liuye,
    .eyebrow_qiubo,
    .eyebrow_wanyue,
    .eyebrow_xinyue,
    .eyebrow_yesheng,
    .eyebrow_yuanshan
]

//眼妆
public let eyeshadowString = [
    "eyeshadow_dadise",
    "eyeshadow_fuguse",
    "eyeshadow_fangtangfen",
    "eyeshadow_huoliju",
    "eyeshadow_jinzongse",
    "eyeshadow_pengkezong",
    "eyeshadow_tianchengse",
    "eyeshadow_xingguangfen",
    "eyeshadow_yanfense",
    "eyeshadow_yeqiangweise",
    "eyeshadow_yuanqicheng"
]

public let eyeshadowType: [MakeupEyeshadowType] = [
    .eyeshadow_dadise,
    .eyeshadow_fuguse,
    .eyeshadow_fangtangfen,
    .eyeshadow_huoliju,
    .eyeshadow_jinzongse,
    .eyeshadow_pengkezong,
    .eyeshadow_tianchengse,
    .eyeshadow_xingguangfen,
    .eyeshadow_yanfense,
    .eyeshadow_yeqiangweise,
    .eyeshadow_yuanqicheng
]

//美瞳
public let pupilString = [
    "pupil_jiaopianzong",
    "pupil_mitangzong",
    "pupil_xingyelan",
    "pupil_jizhouhei",
    "pupil_wuraohui",
    "pupil_chunrifen",
    "pupil_tianchalv",
    "pupil_siyecaolv",
    "pupil_kuangyelan",
    "pupil_qiangweifenhui",
    "pupil_haifenglan"
]

public let pupilType: [MakeupPupilType] = [
    .pupil_jiaopianzong,
    .pupil_mitangzong,
    .pupil_xingyelan,
    .pupil_jizhouhei,
    .pupil_wuraohui,
    .pupil_chunrifen,
    .pupil_tianchalv,
    .pupil_siyecaolv,
    .pupil_kuangyelan,
    .pupil_qiangweifenhui,
    .pupil_haifenglan
]

//腮红
public let blushString = [
    //无辜
    "blush_wugu_naixingse",
    "blush_wugu_naijuse",
    "blush_wugu_mitaoju",
    "blush_wugu_yanxunmeigui",
    "blush_wugu_niunaicaomei",
    //茶艺
    "blush_chayi_naixingse",
    "blush_chayi_naijuse",
    "blush_chayi_mitaoju",
    "blush_chayi_yanxunmeigui",
    "blush_chayi_niunaicaomei",
    //初恋
    "blush_chulian_naixingse",
    "blush_chulian_naijuse",
    "blush_chulian_mitaoju",
    "blush_chulian_yanxunmeigui",
    "blush_chulian_niunaicaomei",
    //纯情
    "blush_chunqing_naixingse",
    "blush_chunqing_naijuse",
    "blush_chunqing_mitaoju",
    "blush_chunqing_yanxunmeigui",
    "blush_chunqing_niunaicaomei",
    //奇迹
    "blush_qiji_naixingse",
    "blush_qiji_naijuse",
    "blush_qiji_mitaoju",
    "blush_qiji_yanxunmeigui",
    "blush_qiji_niunaicaomei",
    //少女
    "blush_shaonv_naixingse",
    "blush_shaonv_naijuse",
    "blush_shaonv_mitaoju",
    "blush_shaonv_yanxunmeigui",
    "blush_shaonv_niunaicaomei"
]

public let blushType: [MakeupBlushType] = [
    //无辜
    .blush_wugu_naixingse,
    .blush_wugu_naijuse,
    .blush_wugu_mitaoju,
    .blush_wugu_yanxunmeigui,
    .blush_wugu_niunaicaomei,
    
    //茶艺
    .blush_chayi_naixingse,
    .blush_chayi_naijuse,
    .blush_chayi_mitaoju,
    .blush_chayi_yanxunmeigui,
    .blush_chayi_niunaicaomei,
    
    //初恋
    .blush_chulian_naixingse,
    .blush_chulian_naijuse,
    .blush_chulian_mitaoju,
    .blush_chulian_yanxunmeigui,
    .blush_chulian_niunaicaomei,
    
    //纯情
    .blush_chunqing_naixingse,
    .blush_chunqing_naijuse,
    .blush_chunqing_mitaoju,
    .blush_chunqing_yanxunmeigui,
    .blush_chunqing_niunaicaomei,
    
    //奇迹
    .blush_qiji_naixingse,
    .blush_qiji_naijuse,
    .blush_qiji_mitaoju,
    .blush_qiji_yanxunmeigui,
    .blush_qiji_niunaicaomei,
    
    //少女
    .blush_shaonv_naixingse,
    .blush_shaonv_naijuse,
    .blush_shaonv_mitaoju,
    .blush_shaonv_yanxunmeigui,
    .blush_shaonv_niunaicaomei,
]

//口红
public let rougeString = [
    "lip_meizise",
    "lip_doushafen",
    "lip_fuguse",
    "lip_guimeihong",
    "lip_jiangguose",
    "lip_nanguase",
    "lip_shiliuhong",
    "lip_mitaose",
    "lip_shanhuse",
    "lip_xingguanghong",
    "lip_anyezi",
    "lip_shaonvfen"
]

public let rougeType: [MakeupRougeType] = [
    .rouge_meizise,
    .rouge_doushafen,
    .rouge_fuguse,
    .rouge_guimeihong,
    .rouge_jiangguose,
    .rouge_nanguase,
    .rouge_shiliuhong,
    .rouge_mitaose,
    .rouge_shanhuse,
    .rouge_xingguanghong,
    .rouge_anyezi,
    .rouge_shaonvfen
]
