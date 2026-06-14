import { UyaliBeautyEngine } from 'uyali_beauty_sdk';

export class BeautyCategory {
  id: string;
  title: string;

  constructor(id: string, title: string) {
    this.id = id;
    this.title = title;
  }
}

export class BeautyItem {
  id: string;
  categoryId: string;
  title: string;
  parameter: string;
  min: number;
  max: number;
  defaultValue: number;

  constructor(id: string, categoryId: string, title: string, parameter: string, min: number, max: number,
    defaultValue: number = 0) {
    this.id = id;
    this.categoryId = categoryId;
    this.title = title;
    this.parameter = parameter;
    this.min = min;
    this.max = max;
    this.defaultValue = defaultValue;
  }
}

export class MakeupGroup {
  id: string;
  title: string;
  parameter: string;
  typeParameter: string;

  constructor(id: string, title: string, parameter: string, typeParameter: string) {
    this.id = id;
    this.title = title;
    this.parameter = parameter;
    this.typeParameter = typeParameter;
  }
}

export class MakeupOption {
  id: string;
  title: string;
  typeValue: number;

  constructor(id: string, title: string, typeValue: number) {
    this.id = id;
    this.title = title;
    this.typeValue = typeValue;
  }
}

export const BEAUTY_CATEGORIES: BeautyCategory[] = [
  new BeautyCategory('beauty', '美颜'),
  new BeautyCategory('reshape', '美型'),
  new BeautyCategory('body', '美体'),
  new BeautyCategory('makeup', '美妆'),
];

export const BEAUTY_ITEMS: BeautyItem[] = [
  new BeautyItem('white', 'beauty', '美白', 'white', 0, 100),
  new BeautyItem('skin', 'beauty', '磨皮', 'skin', 0, 100),
  new BeautyItem('eyeBright', 'beauty', '亮眼', 'eyeBright', 0, 100),
  new BeautyItem('teethBright', 'beauty', '白牙', 'teethBright', 0, 100),
  new BeautyItem('darkCircle', 'beauty', '黑眼圈', 'darkCircle', 0, 100),

  new BeautyItem('headReduce', 'reshape', '小头', 'headReduce', 0, 100),
  new BeautyItem('faceThin', 'reshape', '瘦脸', 'faceThin', 0, 100),
  new BeautyItem('faceNarrow', 'reshape', '窄脸', 'faceNarrow', 0, 100),
  new BeautyItem('faceV', 'reshape', 'V脸', 'faceV', 0, 100),
  new BeautyItem('faceSmall', 'reshape', '小脸', 'faceSmall', 0, 100),
  new BeautyItem('chin', 'reshape', '下巴', 'chin', -50, 50),
  new BeautyItem('forehead', 'reshape', '额头', 'forehead', -50, 50),
  new BeautyItem('cheekbone', 'reshape', '颧骨', 'cheekbone', -50, 50),
  new BeautyItem('eyeBig', 'reshape', '大眼', 'eyeBig', 0, 100),
  new BeautyItem('eyeDistance', 'reshape', '眼距', 'eyeDistance', -50, 50),
  new BeautyItem('eyeCorner', 'reshape', '开眼角', 'eyeCorner', 0, 100),
  new BeautyItem('eyelidDown', 'reshape', '眼睑下至', 'eyelidDown', 0, 100),
  new BeautyItem('noseThin', 'reshape', '瘦鼻', 'noseThin', 0, 100),
  new BeautyItem('noseWing', 'reshape', '鼻翼', 'noseWing', 0, 100),
  new BeautyItem('noseLong', 'reshape', '长鼻', 'noseLong', -50, 50),
  new BeautyItem('noseRoot', 'reshape', '山根', 'noseRoot', 0, 100),
  new BeautyItem('eyebrowDistance', 'reshape', '眉间距', 'eyebrowDistance', -50, 50),
  new BeautyItem('eyebrowThin', 'reshape', '眉粗细', 'eyebrowThin', -50, 50),
  new BeautyItem('mouth', 'reshape', '嘴型', 'mouth', -50, 50),

  new BeautyItem('bodySlim', 'body', '瘦身', 'bodySlim', 0, 100),
  new BeautyItem('waistSlim', 'body', '瘦腰', 'waistSlim', 0, 100),
  new BeautyItem('legSlim', 'body', '瘦腿', 'legSlim', 0, 100),
  new BeautyItem('shoulderNarrow', 'body', '窄肩', 'shoulderNarrow', 0, 100),
  new BeautyItem('armSlim', 'body', '瘦臂', 'armSlim', 0, 100),
  new BeautyItem('calfSlim', 'body', '小腿', 'calfSlim', 0, 100),
  new BeautyItem('abdomenSlim', 'body', '收腹', 'abdomenSlim', 0, 100),
  new BeautyItem('legLong', 'body', '长腿', 'legLong', 0, 100),
  new BeautyItem('bodyHeight', 'body', '增高', 'bodyHeight', 0, 100),
  new BeautyItem('legShape', 'body', '腿型', 'legShape', 0, 100),
  new BeautyItem('neckLength', 'body', '天鹅颈', 'neckLength', 0, 100),
  new BeautyItem('shoulderShape', 'body', '直角肩', 'shoulderShape', 0, 100),
];

export const MAKEUP_GROUPS: MakeupGroup[] = [
  new MakeupGroup('eyebrow', '眉毛', 'makeupEyebrow', 'makeupEyebrowType'),
  new MakeupGroup('eyeshadow', '眼妆', 'makeupEyeshadow', 'makeupEyeshadowType'),
  new MakeupGroup('pupil', '美瞳', 'makeupPupil', 'makeupPupilType'),
  new MakeupGroup('blush', '腮红', 'makeupBlush', 'makeupBlushType'),
  new MakeupGroup('rouge', '口红', 'makeupRouge', 'makeupRougeType'),
];

export function getItemsByCategory(categoryId: string): BeautyItem[] {
  return BEAUTY_ITEMS.filter((item: BeautyItem) => item.categoryId === categoryId);
}

export function getMakeupOptions(groupId: string): MakeupOption[] {
  if (groupId === 'eyebrow') {
    return [
      new MakeupOption('none', '无', 0),
      new MakeupOption('standard', '标准', 1),
      new MakeupOption('thick', '粗平', 2),
      new MakeupOption('soft', '卷烟', 3),
      new MakeupOption('popular', '流星', 4),
      new MakeupOption('willow', '柳叶', 5),
      new MakeupOption('autumn', '秋波', 6),
      new MakeupOption('moon', '弯月', 7),
      new MakeupOption('newMoon', '新月', 8),
      new MakeupOption('wild', '野生', 9),
      new MakeupOption('farHill', '远山', 10),
    ];
  }
  if (groupId === 'eyeshadow') {
    return [
      new MakeupOption('none', '无', 0),
      new MakeupOption('earth', '大地', 1),
      new MakeupOption('brown', '复古', 2),
      new MakeupOption('pink', '方糖粉', 3),
      new MakeupOption('orange', '活力橘', 4),
      new MakeupOption('gold', '金棕', 5),
      new MakeupOption('punk', '朋克棕', 6),
      new MakeupOption('natural', '天成', 7),
      new MakeupOption('starPink', '星光粉', 8),
      new MakeupOption('misty', '烟粉', 9),
      new MakeupOption('rose', '野蔷薇', 10),
      new MakeupOption('vitality', '元气橙', 11),
    ];
  }
  if (groupId === 'pupil') {
    return [
      new MakeupOption('none', '无', 0),
      new MakeupOption('brown', '胶片棕', 1),
      new MakeupOption('honey', '蜜糖棕', 2),
      new MakeupOption('nightBlue', '星夜蓝', 3),
      new MakeupOption('black', '极昼黑', 4),
      new MakeupOption('gray', '雾绕灰', 5),
      new MakeupOption('springPink', '春日粉', 6),
      new MakeupOption('teaGreen', '甜茶绿', 7),
      new MakeupOption('clover', '四叶草绿', 8),
      new MakeupOption('blue', '旷野蓝', 9),
      new MakeupOption('roseGray', '蔷薇粉灰', 10),
      new MakeupOption('seaBlue', '海风蓝', 11),
    ];
  }
  if (groupId === 'blush') {
    return [
      new MakeupOption('none', '无', 0),
      new MakeupOption('rose', '玫瑰', 1),
      new MakeupOption('peach', '蜜桃', 2),
      new MakeupOption('sunset', '日落', 3),
      new MakeupOption('sweet', '甜粉', 4),
      new MakeupOption('milkTea', '奶茶', 5),
      new MakeupOption('apricot', '杏色', 6),
      new MakeupOption('wine', '微醺', 7),
      new MakeupOption('plum', '梅子', 8),
      new MakeupOption('coral', '珊瑚', 9),
      new MakeupOption('vitality', '元气', 10),
    ];
  }
  return [
    new MakeupOption('none', '无', 0),
    new MakeupOption('plum', '梅子色', 1),
    new MakeupOption('bean', '豆沙粉', 2),
    new MakeupOption('retro', '复古色', 3),
    new MakeupOption('roseRed', '贵梅红', 4),
    new MakeupOption('berry', '浆果色', 5),
    new MakeupOption('pumpkin', '南瓜色', 6),
    new MakeupOption('pomegranate', '石榴红', 7),
    new MakeupOption('honeyPeach', '蜜桃色', 8),
    new MakeupOption('coral', '珊瑚色', 9),
    new MakeupOption('starlight', '星光红', 10),
    new MakeupOption('nightPurple', '暗夜紫', 11),
    new MakeupOption('girlPink', '少女粉', 12),
  ];
}

export function syncBeautyState(engine: UyaliBeautyEngine, values: Map<string, number>,
  makeupTypes: Map<string, number>, frontCamera: boolean = false): void {
  engine.setCameraFacing(frontCamera);
  BEAUTY_ITEMS.forEach((item: BeautyItem) => {
    engine.setParameter(item.parameter, values.get(item.parameter) ?? item.defaultValue);
  });
  MAKEUP_GROUPS.forEach((group: MakeupGroup) => {
    engine.setParameter(group.parameter, values.get(group.parameter) ?? 0);
    engine.setMakeupType(group.typeParameter, makeupTypes.get(group.typeParameter) ?? 0);
  });
}

export function applyBeautyState(engine: UyaliBeautyEngine, values: Map<string, number>,
  makeupTypes: Map<string, number>, frontCamera: boolean = false): void {
  engine.resetAllFilters();
  syncBeautyState(engine, values, makeupTypes, frontCamera);
}

export function resetBeautyValues(values: Map<string, number>, makeupTypes: Map<string, number>): void {
  values.clear();
  makeupTypes.clear();
  BEAUTY_ITEMS.forEach((item: BeautyItem) => {
    values.set(item.parameter, item.defaultValue);
  });
  MAKEUP_GROUPS.forEach((group: MakeupGroup) => {
    values.set(group.parameter, 0);
    makeupTypes.set(group.typeParameter, 0);
  });
}
