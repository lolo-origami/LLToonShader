# LLToon概要

トゥーンシェーダーは、より柔軟でイラスト表現を目指した様々な機能を持つオリジナルのシェーダーです。
基本のトゥーンライティングにどんどん光を加算する、という思想で作成されています。暗部での情報量を増やしやすいのが特徴です。
ForwardLightingをベースに、追加光やUnityのLightProbeにも対応しています。

## 説明画像について

このREADMEの説明画像には、第三者が権利を持つキャラクターや3Dモデルが含まれます。説明画像と、画像に含まれるキャラクター・モデルは、LLToonのMITライセンスの対象外です。画像の転載・再利用には、各権利者の利用条件が適用されます。

彩澄りりせのキャラクターは株式会社AHS、MMDモデルはISAO氏によるものです。掲載にあたっては[AHSのキャラクター利用ガイドライン](https://www.ah-soft.com/guideline/)を参照してください。

## Toon機能

### 基本(Diffuse)

- **2段階の影設定**: 「1影」と「2影」の2段階で影を調整します。
  - **ShadowMultColor**: 1影の色を調整します。
  - **ShadowArea**: 1影の範囲を調整します。
  - **ShadowSmooth**: 1影の境界線の滑らかさを調整します。
  - **Use DarkShadow**: 2影を有効にするか設定します。
  - **DarkShadowMultColor**: 2影の色を調整します。
  - **DarkShadowArea**: 2影の範囲を調整します。
  - **DarkShadowSmooth**: 2影の境界線の滑らかさを調整します。

### 追加機能 
- **2影反転による照り返し表現**: 通常の影とは逆の方向に2影を生成し、特殊なライティング効果を作り出すことができます。
  - **InverseDarkShadow**: 逆の2影を有効にするか設定します。
  - <img width="317" height="201" alt="image" src="https://github.com/user-attachments/assets/f7391556-1d41-4ae9-952e-78ce1cbf7f61" />


- **固定されたライトのY軸**: ライトのY軸の値を固定し、常に一定の高さから光が当たっているような表現が可能です。主に顔に対して使われます。
  - **Use FixLightY**: ライトのY軸を無視するか設定します。
  - <img width="209" height="219" alt="image" src="https://github.com/user-attachments/assets/0909a9e7-21ef-43d0-8366-54ed1c63e491" /> <img width="265" height="219" alt="image" src="https://github.com/user-attachments/assets/b630ba78-2ec9-426e-af6e-8645c7f92dbc" />

- **マテリアルごとの影の色**: マスクテクスチャのAチャンネルを利用して、一つのマテリアル内で影の色を2種類使い分けることが可能です。服と肌が同一マテリアルの時等に利用ください。
  - **SceondMaterialShadowColor**: 2つ目のマテリアル用の1影の色を調整します。
  - **SceondMaterialDarkShadowColor**: 2つ目のマテリアル用の2影の色を調整します。
    
- **影色ブレンド**: 影部専用の色情報に切り替えます。シーンでのボリューム設定やTimeline等と組み合わせて活用ください。ベースカラーが1影、1影が1影と2影のブレンド、2影の色が弱まるように設定されています。これは、影の中に入った時にコントラストが弱くなる効果を想定しています。
  - **OnShadowForChara**: 影色ブレンドをオンにします。 

* **EnableFaceCheek**: 顔のシェーディングを有効にするか設定します。

## ハイライト(Specular)関連

トゥーンシェーディングをベースにしつつ、BRDFモデルを使ったハイライト表現を追加することができます。

### 基本
- **EnableSpecular**: スペキュラを有効にするか設定します。
- **LightSpecColor**: スペキュラの色を設定します。
- **BRDF表現**
  - **Metallic**: 金属感を調整します。
  - **Smoothness**: 滑らかさを調整します。
- **スペキュラタイプ切り替え**: `EnableHair`を有効にすることで、髪の毛に異方性反射を元にしたスペキュラを表現できます。
  - **EnableHair**: 髪の毛に特化したスペキュラを有効にするか設定します。
   - **Sharpness**: 髪の毛用スペキュラの鋭さを調整します。
  - **EnableMatCapSpecular (`_EnableMatCapSpecular`)**: Matcapによるスペキュラを有効にするか設定します
    - **MatCapIntensity**: Matcapの強度を調整します。

### 追加機能
- **高輝度スぺキュラ**: より鋭く出したいハイライトを描画できます。
 - **SpecularHighIntensity**: 高強度のスペキュラの強度を調整します。
- **影内ハイライト機能**： 影の中に入っても、ハイライトを描画できます。
  - **ShadowHighlightColor**: 影部分のハイライト色を設定します。
  - **SpecularIntensityShadow**: 影部分のスペキュラの強度を調整します。

## 輝き制御機能(BloomInputs)
Emissionや、リムライト等を制御するための機能です。Specularやベースの色の強さもまとめて制御できます。
### Emission
- **EnableEmission**: エミッションを有効にします。  
- **EmissionColor**: エミッションの色を調整します。  
- **Emission**: エミッションの強度を調整します。  
- **EmissionBloomFactor**: ブルーム計算への寄与率を調整します。  
- **DarkEmissionIntensity**: 影中のエミッション強度を調整します。  
- **EnableEmissionOnly**: 発光のみを描画するか設定します。
- 
### リムライト
- **EnableRim**: リムライトを有効にするか設定します。
- **RimColor**: リムライトの色を調整します。
- **Rim Smooth**: リムライトの境界線の滑らかさを調整します。
- **Rim Pow**: リムライトの広がりを調整します。

### GI
- **FlatGI**: SH関数のサンプリングに「ワールド座標ベクトルの向き」を使います。位置に応じた環境光の変化だけを平面的に足すことができます。
  - **L0 Minus**: 全体的に光が強くなってしまうので、L0の定数項を除算して調整します。
 <img width="503" height="881" alt="image" src="https://github.com/user-attachments/assets/31729a66-42f6-4e91-9bf4-27217e7d4587" />　<img width="509" height="874" alt="image" src="https://github.com/user-attachments/assets/c5c8e746-ded2-4cbb-bb4f-094289b1ad1d" />

#### 追加機能 
- **BlendRimWithBaseColor**: リムライトの色をベースカラーと馴染ませるかどうかの切り替えを設定します。
- **EnableLambertRim**: ライトが当たっている明るい部分ではリムライトが強く出て、影になっている暗い部分ではリムライトが弱くなるように計算されるようになります。
- **EnableDarkRim**: 暗い部分のリムライトを有効にするか設定します。
  - **DarkRimColor**: 暗い部分のリムライトの色を調整します。
  - **Dark Rim Smooth**: 暗い部分のリムライトの強度を調整します。
  - **Rim Pow**: 暗い部分のリムライトの広がりを調整します。

### 固有表現(Unique Input)

#### Tights
- **EnableTights**: タイツ専用ライティングを有効にします。  
- **TightsColor**: タイツの基本色を設定します。  
- **TightsBaseAlpha**: タイツの最低不透明度を調整します。  
- **TightsMaxAlpha**: タイツの最大不透明度（明部の上限）を調整します。  
- **TightsFresnelPow**: フレネルの鋭さを調整します。  
- **TightsFresnelStrength**: フレネルの寄与量を調整します。  
- **TightsBlendStrength**: ベース色とハイライトのブレンド量を調整します。  
- **TightsHighlightMap**: ハイライトマップを設定します。  
- **TightsHighlightScale**: ハイライトマップのスケールを調整します。  
- **TightsHighlightIntensity**: ハイライトの強度を調整します。  
- **UseTightsNoiseTex**: タイツのノイズをテクスチャから使用するか切り替えます。  
- **TightsNoiseTex**: タイツのノイズテクスチャを指定します。  
- **TightsNoiseDir**: ノイズの方向を設定します（0=横筋、1=縦筋）。  
- **TightsNoiseScale**: ノイズの密度を調整します。  
- **TightsNoiseSharpness**: ノイズラインのシャープさを調整します。  
- **TightsNoiseJitter**: ノイズラインの揺らぎを調整します。  
- **TightsSpecThreshold**: スペキュラが発生するしきい値を調整します。  
- **TightsSpecWidth**: スペキュラの遷移幅を調整します。  
- **TightsSpecContrast**: スペキュラのコントラストを調整します。  
- **TightsThighStart**: 腿のハイライトが始まる位置を調整します。  
- **TightsThighEnd**: 腿のハイライトが最大になる位置を調整します。  
- **TightsThighBoost**: 腿部分のハイライト強調度を調整します。  


### 全体調整
- **DiffuseIntensity**: ディフューズの強度を調整します。
- **SpecularIntensity**: スペキュラの強度を調整します。
- **WorldLightInfluence**: メインのディレクショナルライトの影響度を調整します。
- **GIInfluence**: グローバルイルミネーション（GI）の総合的な影響度を調整します。
- **AddLightInfluence**: 追加ライトの影響度を調整します。
- **LightMapInfluence**: ライトマップの影響度を調整します。ベイクされたGIに影響します。
- **BloomRimSpecFactor**: ハイライト、リムライト、エミッションを総合的に調整します。最終的なグローの調整に使ってください


### Outline
SobelFilterを利用したアウトライン制御です。外側はdepth、内側は法線を元に判定しています。
- **OutlineMask**: アウトラインの表示/非表示を制御します。  
- **OutlineWidth**: アウトラインの太さを調整します。  
- **OutlineLightAffects**: アウトラインのライティング影響度を調整します。  
- **OutlineSaturation**: アウトラインの彩度を調整します。  
- **OutlineBrightness**: アウトラインの明るさを調整します。  
- **OutlineStrength**: 内側アウトラインの強度を調整します。  
- **OutlineSmoothness**: 内側アウトラインの滑らかさを調整します。  
- **InnerWidth**: 内側線の太さを調整します。  
- **InnerStrength**: 内側線の強度を調整します。  
- **InnerThreshold**: 内側線を出すためのしきい値を調整します。  
- **InnerSmoothness**: 内側線のフェードを調整します。 

# LLPostProcess概要

独自のVolumePostProcessです。
URPのRendererに使いたいPostProcessを登録してください。
RenderFeatureの登録順で実行順が自動入れ替わります。

<img width="460" height="110" alt="image" src="https://github.com/user-attachments/assets/8a432cd5-2d1f-4111-a3f5-4b8b5be3ea85" />


## DepthFog

カメラの Depth Textureを元にした距離依存のフォグ使います。

<img width="312" height="559" alt="image" src="https://github.com/user-attachments/assets/33f6f876-36e7-47d5-9fe8-fb4f20d45397" /> <img width="312" height="559" alt="image" src="https://github.com/user-attachments/assets/99ed65f0-464d-468c-a292-5ff353b90af5" />

<img width="458" height="97" alt="image" src="https://github.com/user-attachments/assets/a26a83e3-25a8-4ac0-a87a-207f06586f2e" />

- **FogColor**: フォグの色。
- **FogIntensity**: Fogの強さ。

## DepthLightShaft

カメラの Depth Textureを元にしたゴッドレイ効果を出力します。ブラー効果のみで軽量に動作することが可能です。
ブラーを特定方向に二回かけて、ボケを大きくしています。

<img width="353" height="630" alt="image" src="https://github.com/user-attachments/assets/2ef96f47-ad4e-4995-a835-1197718c93bf" />

<img width="357" height="628" alt="image" src="https://github.com/user-attachments/assets/f8a77603-ceda-4503-a551-ce597b9d0f01" />

<img width="467" height="233" alt="image" src="https://github.com/user-attachments/assets/e0c65bf4-aa6a-4c7b-a697-f9878c3790a3" />

- **BlurDirection**: ぼかす方向
- **BlurSizeA**: 一回目のブラーサイズ
- **BlurSizeB**: 二回目のブラーサイズ
- **LightShaftColor**:ゴッドレイの色
- **DepthRange**：どのデプス値までをマスクにするか
- **BlendMode**:合成モード
- **BlendIntensity**:合成の強さ  


## Flare

アニメやイラストで加工に使われる、特定箇所へのグラデーション設定です。

## Diffusion

<img width="352" height="628" alt="image" src="https://github.com/user-attachments/assets/d13c8c09-a9ac-4477-ac81-d761ceb3d2d4" /> <img width="353" height="628" alt="image" src="https://github.com/user-attachments/assets/ab0f6cdf-1b2f-4f0b-9556-557023c2f30e" />

<img width="509" height="176" alt="image" src="https://github.com/user-attachments/assets/424d6a6c-9c6e-443e-b67f-8b2e11226c22" />



光が拡散するような画像加工を行います。
コントラストを調整し、縦横のブラーをかけた後に合成を行います。
合成は、加算、スクリーン、覆い焼きカラー、比較(明)が選べます。

- **Contrast**:合成前の元画像のコントラストを強める  
- **BlurSize**:ぼかしの強さ  
- **BlendMode**:合成モード
- **BlendIntensity**:合成の強さ  

## SSRaymarchLightShaft

<img width="309" height="553" alt="image" src="https://github.com/user-attachments/assets/7ba09c8a-30b0-42ea-882d-4e26b5fc2add" /> <img width="309" height="554" alt="image" src="https://github.com/user-attachments/assets/58afbe7d-6203-4b13-a174-7ee312af5730" />

<img width="462" height="362" alt="image" src="https://github.com/user-attachments/assets/c4fe836e-5d11-49ec-9372-ff89ff1b83c5" />


スクリーンスペースでレイマーチ処理を行ってゴッドレイ効果を出すものです。
遮蔽物が画面内にあれば、その後ろで光がさえぎられている効果を足せます。レイマーチなので重たいです。
複数の合成モードを選択できます。

- **RayColor**: レイの基本色。距離に応じてシーンカラーとブレンドされる色。  
- **RayIntensity**：レイの強さ
- **MaxIterations**：サンプリング回数。大きくするとフォグの精度が上がるが、処理コストも増える。  
- **MinDistance**:カメラからレイマーチ開始距離。
- **MaxDistance**:レイマーチ終了距離。  
- **Decay**:レイを減衰させる係数。1.0 で減衰なし、0.9 などで徐々に薄れていく。  
- **FalloffPower**:密度変化を制御するカーブ。小さい値で均一、大きくすると距離に応じて急激に濃くなる。  
- **JitterStrength**:サンプリング位置にランダムな揺らぎを与える。  
- **NoiseScale**:ノイズテクスチャのスケール。
- **BlendMode**:合成モード
- **BlendIntensity**:合成の強さ  

## SSRaymarchFog

<img width="313" height="552" alt="image" src="https://github.com/user-attachments/assets/2e3df06f-9bf0-4a64-9ec2-f272ada1b4d1" /> <img width="309" height="549" alt="image" src="https://github.com/user-attachments/assets/306691fc-99e2-4f3d-b4fb-4400501c2045" />

<img width="469" height="204" alt="image" src="https://github.com/user-attachments/assets/6c108260-7b4d-4721-a9c3-ebd62ca3b69e" />

スクリーンスペースでレイマーチ処理を行ってフォグ効果を出すものです。
Depthだけで行うフォグよりも、遮蔽物とフォグがかかる箇所がくっきりしています。レイマーチなので重たいです。
複数の合成モードを選択できます。

- **FogColor**：フォグの色
- **FogIntensity**：フォグの強さ
- **MaxIterations**：サンプリング回数。大きくするとフォグの精度が上がるが、処理コストも増える。  
- **MinDistance**:カメラからレイマーチ開始距離。
- **MaxDistance**:レイマーチ終了距離。
- **BlendMode**:合成モード
- **BlendIntensity**:合成の強さ   

## GuidedFilter
<img width="313" height="553" alt="image" src="https://github.com/user-attachments/assets/4f25f0c2-c216-4a3e-a18e-b7c5367abd9c" /> <img width="313" height="552" alt="image" src="https://github.com/user-attachments/assets/3a83eb83-190b-45bc-9732-1f5a91723b95" />

<img width="472" height="199" alt="image" src="https://github.com/user-attachments/assets/78f46285-4f45-45e8-a392-41a5b92b3ca3" />

ガイド画像を用いてエッジを保持しつつ平滑化するフィルタ。
ガイド画像には「入力カラー（Self）」「深度（Depth）」「外部テクスチャ（Other）」を選択可能。
単純なブラーと異なり、エッジ付近の構造を保ちながら滑らかにすることができる。

- **Radius**：フィルタの半径。大きくするとより広範囲が平滑化されるが、処理コストも増加します。
- **Eps**：正則化パラメータ。小さい値にすると入力画像に忠実、大きくすると平滑化が強くなります。
- **GuideMode**：ガイド画像の種類を選択します。
  - Self：入力カラーそのものをガイドに利用。色味をなるべく保ちながら平滑化。
  - Depth：カメラ深度を二値化したマスクをガイドに利用。奥行きに沿ってフォグ・マスク的な平滑化を実現。
  - Other：外部に指定したテクスチャをガイドに利用。マスク画像や別のレンダリング結果を活用可能。
- **GuideTex**：外部ガイド用テクスチャ。GuideMode=Other のときのみ利用。
- **DepthThreshold**：Depthモード時のしきい値。カメラからの深度を基準に、手前と奥を分ける境界を決定します。
- **DepthFeather**：Depthモード時のフェザー幅。しきい値付近をなめらかに補間することで、エッジのギザつきを防ぎます。
- **DepthColorBlend**：Depthモード時のみ有効。フィルタ結果 q と元カラー p をブレンドする割合。

## AnimeToneMap

アニメ的な色彩、彩度とコントラストを保持しながら、必要に応じてガンマ補正やハイライト圧縮を行います。。

黒の持ち上げ

<img width="351" height="628" alt="image" src="https://github.com/user-attachments/assets/466bbb25-725a-4dfc-ba52-08f8c63869a0" />

<img width="351" height="628" alt="image" src="https://github.com/user-attachments/assets/1adc0ea6-b7bc-4070-97e8-ce691f8e423f" />


白飛びの軽減

<img width="352" height="628" alt="image" src="https://github.com/user-attachments/assets/ca9fca90-877d-4542-a30f-35a1ba7268b3" />

<img width="351" height="628" alt="image" src="https://github.com/user-attachments/assets/22777c8f-6cdd-445e-ba1e-6680a1565563" />


Unity標準のACES(比較用)

<img width="352" height="626" alt="image" src="https://github.com/user-attachments/assets/9b470c9b-010d-4221-b9fd-1f7386d670fd" />

<img width="354" height="624" alt="image" src="https://github.com/user-attachments/assets/6ed8b78f-1fd1-426e-bea4-53ae7f26b118" />

- **Gamma**：ガンマ補正で明暗を強調します。
- **Contrast**：コントラストを強め、ベタ塗り感を保ちます。
- **Saturation**：彩度を調整し、鮮やかさを維持します。
- **HighlightCompress**：明部のみに適用される圧縮カーブで、白飛びを防ぎます。
- **WhitePoint**：圧縮カーブを適用する輝度値





