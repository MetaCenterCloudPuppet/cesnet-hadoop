class{'::hadoop':
  realm => '',
}
hadoop::kinit{'my-kinit':
  touchfile => 'my_touch_file',
}
