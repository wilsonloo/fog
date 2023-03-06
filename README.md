## 背景
* 玩法：派遣斥候进行地图探索，一边探索一边解开迷雾，这些迷雾解开后不可重新掩盖迷雾
* 应用场合：某些系统在地图上创建其他游戏对象时，需要判定地图上的位置是否已经解开

---
## 实现
* 采用四叉树进行数据存储，判定地图是否解开即为查询四叉树
* 特性1. 迷雾探索是不会重置，随着探索的继续最终会探索完整张图；  
    而四叉树的常规用法是添加元素时，满足条件时不断继续进行切割，会导致叶子节点变多，尤其是探索完成整张地图时
    在此进行优化，如果一个区域内的所有单元格都探索完成，则进行合并，不再进行分割，因为不会进行重复探索；只有在区域内的单元格并非全部探索完，才进行分割
    
---    
## 实现步骤和细节
* 四叉树的每个区域最多能存储2个节点，超多时进行分割
  ![./doc/11_区域最大节点数.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/11_%E5%8C%BA%E5%9F%9F%E6%9C%80%E5%A4%A7%E8%8A%82%E7%82%B9%E6%95%B0.png)

* 在添加了第3个格子c 后，进行切割，直至每个区域最多容纳2个格子
  具体流程是，先将格子添加到区域的节点列表，再进行4相现拆分，再将这3个格子重新塞入:
  ![./doc/12_触发切割.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/12_%E8%A7%A6%E5%8F%91%E5%88%87%E5%89%B2.png)

* 添加新格子d，不触发切割：
  ![./doc/13_新增格子d.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/13_%E6%96%B0%E5%A2%9E%E6%A0%BC%E5%AD%90d.png) 

* 添加新格子e后其中一种效果：
  ![./doc/14_添加e后的效果.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/14_%E6%B7%BB%E5%8A%A0e%E5%90%8E%E7%9A%84%E6%95%88%E6%9E%9C.png)

  在新增e后，将切割成4个象限
  ![./doc/15_添加e后切割4个象限.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/15_%E6%B7%BB%E5%8A%A0e%E5%90%8E%E5%88%87%E5%89%B24%E4%B8%AA%E8%B1%A1%E9%99%90.png)

  先重新添加格子b，在当前区域内将分成四个格子1、2、3、4  
  再重新添加格子d，在当前区域内将分成二个格子5、6,而格子3和5会先进行融合成一个格子3-5  
  再重新添加格子e，加入象限3-5, 格子数目新增到二个。
  ![./doc/16_添加e后重新添加bd.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/16_%E6%B7%BB%E5%8A%A0e%E5%90%8E%E9%87%8D%E6%96%B0%E6%B7%BB%E5%8A%A0bd.png)
  最终成为：
  ![./doc/14_添加e后的效果.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/14_%E6%B7%BB%E5%8A%A0e%E5%90%8E%E7%9A%84%E6%95%88%E6%9E%9C.png)

* 添加e后的另一种效果（按照b、e、d的顺序）：
  ![./doc/17_添加e后的另一种情况.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/17_%E6%B7%BB%E5%8A%A0e%E5%90%8E%E7%9A%84%E5%8F%A6%E4%B8%80%E7%A7%8D%E6%83%85%E5%86%B5.png)

* 添加f无法融合：
  ![./doc/18_添加f无法融合.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/18_%E6%B7%BB%E5%8A%A0f%E6%97%A0%E6%B3%95%E8%9E%8D%E5%90%88.png)

* 添加g到空区域:
  ![./doc/19_添加g到空区域.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/19_%E6%B7%BB%E5%8A%A0g%E5%88%B0%E7%A9%BA%E5%8C%BA%E5%9F%9F.png)

* 添加A到空区域：
  ![./doc/20_添加A到空区域.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/20_%E6%B7%BB%E5%8A%A0A%E5%88%B0%E7%A9%BA%E5%8C%BA%E5%9F%9F.png)

* 添加B并和A进行融合：
  ![./doc/21_添加B并和A进行融合.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/21_%E6%B7%BB%E5%8A%A0B%E5%B9%B6%E5%92%8CA%E8%BF%9B%E8%A1%8C%E8%9E%8D%E5%90%88.png)

* 添加C但不能进行融合：
  ![./doc/22_添加C但不能进行融合.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/23_%E6%B7%BB%E5%8A%A0D%E8%BF%9B%E8%A1%8C%E8%9E%8D%E5%90%88.png)

* 添加D进行融合：
  ![./doc/23_添加D进行融合.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/23_%E6%B7%BB%E5%8A%A0D%E8%BF%9B%E8%A1%8C%E8%9E%8D%E5%90%88.png)

* 添加Z，然后进行融合：
  ![./doc/24_添加Z.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/24_%E6%B7%BB%E5%8A%A0Z.png)

* 添加Z后和周围格子融合，其中一个区域都填满，标记为full，区域为绿色，并删除其所有节点类表和children，以节省节省空间：
  ![./doc/25_添加Z后和周围格子融合.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/25_%E6%B7%BB%E5%8A%A0Z%E5%90%8E%E5%92%8C%E5%91%A8%E5%9B%B4%E6%A0%BC%E5%AD%90%E8%9E%8D%E5%90%88.png)

* 添加X进行融合：
  ![./doc/26_添加X进行融合.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/26_%E6%B7%BB%E5%8A%A0X%E8%BF%9B%E8%A1%8C%E8%9E%8D%E5%90%88.png)

* 添加W进行融合,并且整个区域填满为full， 但此时3个区域为child，虽然满了，但还不能进行再次融合，需要待四个区域都为full：
  ![./doc/27_添加W进行融合.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/27_%E6%B7%BB%E5%8A%A0W%E8%BF%9B%E8%A1%8C%E8%9E%8D%E5%90%88.png)

* 添加v合并：
  ![./doc/28_添加v合并.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/28_%E6%B7%BB%E5%8A%A0v%E5%90%88%E5%B9%B6.png)

* 添加u合并：
  ![./doc/29_添加u合并.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/29_%E6%B7%BB%E5%8A%A0u%E5%90%88%E5%B9%B6.png)

* 添加t后合并：
  ![./doc/30_添加t后合并.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/30_%E6%B7%BB%E5%8A%A0t%E5%90%8E%E5%90%88%E5%B9%B6.png)

* 添加t后,四个区域都为full，再次向上合并:
  ![./doc/31_添加t后向上合并.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/31_%E6%B7%BB%E5%8A%A0t%E5%90%8E%E5%90%91%E4%B8%8A%E5%90%88%E5%B9%B6.png)

---
## 如何使用：
* 主要文件为 fog.lua 模块文件， 设计以下几个函数：
  1. Fog.new(WIDTH, HEIGH, args)  
    WIDTH：地图宽度  
    HEIGH: 地图高度  
    args: 命令行参数列表，主要是-d -e 参数（下面有测试用例说明)  

  2. fog:add_rects(矩形列表)  
    矩形元素格式为  
    ```lua
      {
        id = 字符串id,  
        x = ?, y = ?, w = ?, h = ?  
      }
    ``` 
  3. fog:check_collision(x, y, w, h)  
    检测矩形(x,y,w,h) 是否在地图中发生了碰撞

* 纯测试产生四叉树：
  ```sh
  lua ./test.lua
  ```

* 打印调试性log, 启动 -d 选项
  ```sh
  lua ./test.lua -d
  ```

* 导出调试性图片, 启动 -e 选项，该导出需要依赖 imgexporter 库
  ```sh
  make
  lua ./test.lua -e
  ```
  这一步骤会将每个步骤的这个树导出json文件到 output目录（假定是/data/output）;
  第二步，git@github.com:wilsonloo/imggenerater.git
  然后执行以下指令即可在同一个output目录看到对应的图片：
  ```sh
  cd imggenerater
  python3 generate.py /data/output
  ```

* 碰撞检测，下图三个黄色区域为测试格子，其中"?-1"标记的格子发生了碰撞， “?-0”标记的格子没有发生碰撞：
  ![./doc/32_测试碰撞.png](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/32_%E6%B5%8B%E8%AF%95%E7%A2%B0%E6%92%9E.png)

---
## 后续优化
  每次新增矩形时，都会进行分给和合并；可以将迷雾数据拆分成两个部分，第一部分是当前的四叉树，第二部分是正在继续探索出来的迷雾列表，在探索完成时将第二部分的内部的矩形进行合并产生较少数量的格子，再依次加入到第一部分的四叉树当中；在探索过程中发生的 碰撞判断，首先在第一部分的四叉树继续判断， 查找不到时再在第二部分数据中进行判断；  

  一个问题是第二部分数据如何进行合并，假如探索是完全自动整张地图，第二部分会就退化成穷举法。  
  
  为第二部分数据设定一个格子数上限，当达到上限时马上进行合并。