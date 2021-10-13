var config = {
  props: ['config'],
  template: `
    <div>
      <h4>Frab Plugin</h4>
      <div class='row'>
        <div class='col-xs-3'>
          <select class='btn btn-default' v-model="mode">
            <option value="all_talks">All Talks</option>
          </select>
        </div>
        <div class='col-xs-3'>
          <select class='btn btn-default' v-model="font_size">
            <option value="40">40px</option>
            <option value="50">50px</option>
            <option value="60">60px</option>
            <option value="70">70px</option>
            <option value="80">80px</option>
            <option value="90">90px</option>
            <option value="100">100px</option>
            <option value="110">110px</option>
            <option value="150">150px</option>
            <option value="200">200px</option>
          </select>
        </div>
      </div>
    </div>
  `,
  computed: {
    mode: ChildTile.config_value('mode', 'all_talks'),
    font_size: ChildTile.config_value('font_size', 70, parseInt),
  }
}

ChildTile.register({
  config: config,
});
